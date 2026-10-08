/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class InstallerDaemon.RepartBackend : InstallerInterface, GLib.Object {
    private const string REPART_SRC = "/opt/repart-target";
    private const string SQUASH_MOUNT = "/mnt/source-image";

    private void log_message (InstallerDaemon.LogLevel level, string format, ...) {
        var msg= format.vprintf (va_list ());

        on_log_message (level, msg);

        switch (level) {
            case TRACE:
                debug (msg);
                break;
            case DEBUG:
                debug (msg);
                break;
            case INFO:
                info (msg);
                break;
            case WARN:
                warning (msg);
                break;
            case ERROR:
                critical (msg);
                break;
            default:
                message (msg);
                break;
        }
    }

    private string? find_first_file (string directory, string suffix) throws GLib.Error {
        try {
            var dir = File.new_for_path (directory);
            var enumerator = dir.enumerate_children (
                FileAttribute.STANDARD_NAME + "," +
                FileAttribute.STANDARD_TYPE,
                FileQueryInfoFlags.NONE
            );

            FileInfo? info;
            while ((info = enumerator.next_file ()) != null) {
                if (info.get_file_type () != FileType.REGULAR) {
                    continue;
                }

                var name = info.get_name ();
                if (name.has_suffix (suffix)) {
                    return Path.build_filename (directory, name);
                }
            }
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.WARN, "Could not find first file in directory %s with suffix %s: %s", directory, suffix, e.message);
        }
        return null;
    }

    private string find_install_squashfs () throws GLib.Error {
        var output = run_capture ({"findmnt", "-rn", "-t", "iso9660,udf", "-o", "TARGET"});
        foreach (var line in output.split ("\n")) {
            var target = line.strip ();
            if (target == "") {
                continue;
            }

            var extra = Path.build_filename (target, "extra");
            var raw_squashfs = find_first_file (extra, ".raw.squashfs");
            if (raw_squashfs != null) {
                return raw_squashfs;
            }
        }

        throw new GLib.IOError.FAILED ("No .raw.squashfs file found.");
    }

    private string run_capture (string[] argv) throws GLib.Error {
        var process = new Subprocess.newv (argv, STDOUT_PIPE | STDERR_MERGE);
        string? stdout_buf;

        if (!process.communicate_utf8 (null, null, out stdout_buf, null)) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Run command failed: %s", string.joinv (" ", argv));
            throw new GLib.IOError.FAILED ("Run command failed: %s", string.joinv (" ", argv));
        }

        return stdout_buf.strip ();
    }

    private void run (string[] argv) throws GLib.Error {
        try {
            var launcher = new SubprocessLauncher (NONE);
            var process = launcher.spawnv (argv);
            process.wait_check ();
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Run command failed: %s: %s", string.joinv (" ", argv), e.message);
            throw new GLib.IOError.FAILED ("Run command failed: %s: %s", string.joinv (" ", argv), e.message);
        }
    }

    public bool has_tpm2 () throws GLib.Error {
        try {
            var output = run_capture ({"systemd-analyze", "has-tpm2"});
            var lines = output.split ("\n");
            return lines.length > 0 && lines[0].strip () == "yes";
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.WARN, "TPM2 check failed: %s", e.message);
            return false;
        }
    }

    private void set_repart_encryption (string value) throws GLib.Error {
        var path = Path.build_filename (REPART_SRC, "40-root.conf");
        var keyfile = new KeyFile ();
        keyfile.load_from_file (path, NONE);
        keyfile.set_string ("Partition", "Encrypt", value);
        keyfile.save_to_file (path);
        log_message (InstallerDaemon.LogLevel.INFO, "Encryption mode: %s", value);
    }

    private void configure_encryption (bool encrypt, string password, ref string[] repart_args, ref string keyfile) throws GLib.Error {
        if (!encrypt) {
            set_repart_encryption ("off");
            return;
        }

        if (password.length == 0 && has_tpm2 ()) {
            set_repart_encryption ("tpm2");
            return;
        }

        set_repart_encryption ("key-file");

        int fd = FileUtils.open_tmp ("elementary-key-file-XXXXXX", out keyfile);
        if (fd < 0) {
            throw new GLib.IOError.FAILED ("Could not create encryption key file");
        }

        FileUtils.chmod (keyfile, 0600);

        var stream = FileStream.fdopen (fd, "w");
        if (stream == null) {
            FileUtils.close (fd);
            throw new GLib.IOError.FAILED ("Could not create encryption key file");
        }

        stream.puts (password);
        stream.flush ();

        var args = repart_args;
        args += "--key-file=" + keyfile;
        repart_args = args;
    }

    private void cleanup (bool squashfs_mounted, string keyfile) throws GLib.Error {
        if (squashfs_mounted) {
            var file = File.new_for_path (SQUASH_MOUNT);
            file.unmount_mountable_with_operation.begin (FORCE, null, null, (obj, res) => {
                try {
                    file.unmount_mountable_with_operation.end (res);
                    log_message (InstallerDaemon.LogLevel.INFO, "Unmounted squashfs");
                } catch (GLib.Error e) {
                    log_message (InstallerDaemon.LogLevel.WARN, "Cleanup unmount %s failed: %s", SQUASH_MOUNT, e.message);
                }
            });
            FileUtils.remove (SQUASH_MOUNT);
            log_message (InstallerDaemon.LogLevel.INFO, "Removed squashfs mount point");
        }

        // Is shred even necessary in a live ISO session?

        /*
        if (keyfile.length > 0) {
            try {
                run ({"shred", "-u", keyfile});
            } catch (GLib.Error e) {
                log_message (InstallerDaemon.LogLevel.WARN, "Cleanup keyfile failed: %s", e.message);
                FileUtils.unlink (keyfile);
            }
        }
        */

        log_message (InstallerDaemon.LogLevel.INFO, "Cleanup done");
    }

    public void install_with_default_disk_layout (InstallConfig config, string disk, bool encrypt, string encryption_password) throws GLib.Error {
        log_message (InstallerDaemon.LogLevel.INFO, "Clean install to " + disk);
        install (disk, encrypt, encryption_password);
    }

    public void install_with_custom_disk_layout (InstallConfig config, Mount[] disk_config, LuksCredentials[] credentials) throws GLib.Error {
        log_message (InstallerDaemon.LogLevel.ERROR, "Custom installations unsupported");
        throw new GLib.IOError.FAILED ("Custom installations unsupported");
    }

    private void install (string dest_dev, bool encrypt, string encryption_password) throws GLib.Error {
        var status = InstallerDaemon.Status () {
            step = INIT,
            percent = 0
        };

        on_status (status);

        var squashfs_mounted = false;
        var keyfile = "";

        try {
            var raw_squashfs = find_install_squashfs ();

            log_message (InstallerDaemon.LogLevel.INFO, "Found squashfs %s", raw_squashfs);

            string[] repart_args = {};

            configure_encryption (encrypt, encryption_password, ref repart_args, ref keyfile);

            status.step = InstallerDaemon.Step.PARTITION;
            status.percent = 10;
            on_status (status);

            /*
            run ({"/usr/sbin/wipefs", "-a", dest_dev});

            log_message (InstallerDaemon.LogLevel.INFO, "Wiped destination device %s", dest_dev);
            */


            DirUtils.create_with_parents (SQUASH_MOUNT, 0755);

            log_message (InstallerDaemon.LogLevel.INFO, "Created squashfs mount point %s", SQUASH_MOUNT);

            // At least one other installer (Calamares) also uses mount terminal command
            run ({"mount", "-t", "squashfs", "-o", "loop,ro", raw_squashfs, SQUASH_MOUNT});

            squashfs_mounted = true;

            log_message (InstallerDaemon.LogLevel.INFO, "Mounted squashfs %s", raw_squashfs);

            var raw_src = find_first_file (SQUASH_MOUNT, ".raw");
            if (raw_src == null) {
                throw new GLib.IOError.FAILED ("Could not locate raw image inside squashfs");
            }

            string[] repart_command = {
                "systemd-repart",
                "--copy-from=" + raw_src,
                "--definitions=" + REPART_SRC,
                "--dry-run=no",
                "--empty=force"
            };

            foreach (var repart_arg in repart_args) {
                repart_command += repart_arg;
            }

            repart_command += dest_dev;

            status.step = InstallerDaemon.Step.EXTRACT;
            status.percent = 20;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Running systemd-repart");

            run_capture (repart_command);

            status.percent = 80;
            on_status (status);

            run ({"partprobe", dest_dev});

            log_message (InstallerDaemon.LogLevel.INFO, "Completed partprobe");

            status.percent = 90;
            on_status (status);

            run ({"udevadm", "settle"});

            log_message (InstallerDaemon.LogLevel.INFO, "Completed udevadm settle");

            log_message (InstallerDaemon.LogLevel.INFO, "Completed installation");

            cleanup (squashfs_mounted, keyfile);

            status.step = InstallerDaemon.Step.BOOTLOADER;
            status.percent = 100;
            on_status (status);
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Installation aborted: " + e.message);
            cleanup (squashfs_mounted, keyfile);
            throw new GLib.IOError.FAILED ("Installation aborted: " + e.message);
        }
    }

    public InstallerDaemon.PartitionTable bootloader_detect () throws GLib.Error {
        log_message (InstallerDaemon.LogLevel.ERROR, "Not implemented");
        throw new GLib.IOError.FAILED ("Not implemented");
    }

    private string get_contents (string path, bool strip = true) throws GLib.Error {
        string contents = "";
        if (FileUtils.test (path, EXISTS)) {
            FileUtils.get_contents (path, out contents);
            if (strip) {
                contents = contents.strip ();
            }
        }
        return contents;
    }

    public DiskInfo get_disks (bool get_partitions = false) throws GLib.Error {
        if (get_partitions) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Get partitions not implemented");
            throw new GLib.IOError.FAILED ("Get partitions not implemented");
        }

        DiskInfo disk_info = DiskInfo () {
            physical_disks = {},
            logical_disks = {}
        };

        Disk[] physical_disks = {};

        try {
            uint64 time_read;
            var installer_device_path = new UnixMountEntry ("/cdrom", out time_read).get_device_path ();

            var sys_block = File.new_for_path ("/sys/block");
            var enumerator = sys_block.enumerate_children (
                FileAttribute.STANDARD_NAME,
                FileQueryInfoFlags.NONE
            );

            FileInfo info;
            while ((info = enumerator.next_file ()) != null) {
                var name = info.get_name ();

                var name_path = Path.build_filename ("/sys/block", name);

                var is_installer_device = installer_device_path.has_prefix (Path.build_filename ("/dev", name));

                // We only want candidate disks for installation
                if (!FileUtils.test (Path.build_filename (name_path, "device"), EXISTS) ||
                    name.has_prefix ("sr") ||
                    is_installer_device) {
                    continue;
                }

                uint64 size;
                uint64 sector_size;
                bool rotational;
                bool removable;

                uint64.try_parse (get_contents (Path.build_filename (name_path, "size")), out size);
                uint64.try_parse (get_contents (Path.build_filename (name_path, "queue", "logical_block_size")), out sector_size);
                bool.try_parse (get_contents (Path.build_filename (name_path, "queue", "rotational")), out rotational);
                bool.try_parse (get_contents (Path.build_filename (name_path, "removable")), out removable);

                var vendor = get_contents (Path.build_filename (name_path, "device", "vendor"));
                var model = get_contents (Path.build_filename (name_path, "device", "model"));

                physical_disks += Disk () {
                    name = "%s%s%s".printf (vendor, vendor.length > 0 ? " " : "", model),
                    partitions = {},
                    sectors = size * 512 / sector_size,
                    sector_size = sector_size,
                    rotational = rotational,
                    removable = removable,
                    device_path = Path.build_filename ("/dev", name)
                };
            }
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Failed to enumerate physical disks: %s", e.message);
            throw new GLib.IOError.FAILED ("Failed to enumerate physical disks: %s", e.message);
        }

        disk_info.physical_disks = physical_disks;

        return disk_info;
    }

    public int decrypt_partition (string path, string pv, string password) throws GLib.Error {
        log_message (InstallerDaemon.LogLevel.ERROR, "Not implemented");
        throw new GLib.IOError.FAILED ("Not implemented");
    }

    public Disk get_logical_device (string pv) throws GLib.Error {
        log_message (InstallerDaemon.LogLevel.ERROR, "Not implemented");
        throw new GLib.IOError.FAILED ("Not implemented");
    }
}
