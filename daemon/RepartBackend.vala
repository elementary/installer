/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[DBus (name = "io.elementary.InstallerDaemon")]
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
        var process = new Subprocess.newv (argv, STDOUT_PIPE | STDERR_PIPE);
        string stdout_buf = "";
        string stderr_buf = "";

        process.communicate_utf8 (null, null, out stdout_buf, out stderr_buf);

        if (!process.get_successful ()) {
            throw new GLib.IOError.FAILED (
                "Run command failed: %s: %s: %s",
                string.joinv (" ", argv),
                stderr_buf.strip (),
                stderr_buf.strip ()
            );
        }

        return stdout_buf.strip ();
    }

    private void run (string[] argv) throws GLib.Error {
        try {
            var launcher = new SubprocessLauncher (NONE);
            var process = launcher.spawnv (argv);
            process.wait_check ();
        } catch (GLib.Error e) {
            throw new GLib.IOError.FAILED ("Run command failed: %s: %s", string.joinv (" ", argv), e.message);
        }
    }

    private bool has_tpm2 () {
        try {
            var output = run_capture ({"systemd-analyze", "has-tpm2"});
            var lines = output.split ("\n");
            return lines.length > 0 && lines[0].strip () == "yes";
        } catch (GLib.Error e) {
            return false;
        }
    }

    private void set_repart_encryption (string value) throws GLib.Error {
        var path = Path.build_filename (REPART_SRC, "40-root.conf");
        string contents = "";

        FileUtils.get_contents (path, out contents);

        var regex = new Regex ("^Encrypt=.*$", MULTILINE);
        contents = regex.replace (contents, contents.length, 0, "Encrypt=" + value);

        FileUtils.set_contents (path, contents);
    }

    private void configure_encryption (bool encrypt, string password, GenericArray<string> repart_args, ref string keyfile) throws GLib.Error {
        if (!encrypt) {
            log_message (InstallerDaemon.LogLevel.INFO, "No encryption");
            set_repart_encryption ("off");
            return;
        }

        if (has_tpm2 () && password.length == 0) {
            log_message (InstallerDaemon.LogLevel.INFO, "TPM2 encryption");
            set_repart_encryption ("tpm2");
            return;
        }

        log_message (InstallerDaemon.LogLevel.INFO, "Password encryption");

        set_repart_encryption ("key-file");

        int fd = FileUtils.open_tmp ("elementary-key-file-XXXXXX", out keyfile);
        if (fd < 0) {
            throw new GLib.IOError.FAILED ("Could not create encryption key file");
        }

        Posix.fchmod (fd, 0600);

        var stream = FileStream.fdopen (fd, "w");
        if (stream == null) {
            Posix.close (fd);
            throw new GLib.IOError.FAILED ("Could not create encryption key file");
        }

        stream.puts (password);
        stream.flush ();

        repart_args.add ("--key-file=" + keyfile);
    }

    private void cleanup (string keyfile) throws GLib.Error {
        log_message (InstallerDaemon.LogLevel.INFO, "Cleanup");

        try {
            run ({"umount", SQUASH_MOUNT});
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.WARN, "Cleanup unmount %s failed: %s", SQUASH_MOUNT, e.message);
        }

        Posix.rmdir (SQUASH_MOUNT);

        if (keyfile.length > 0) {
            try {
                run ({"shred", "-u", keyfile});
            } catch (GLib.Error e) {
                log_message (InstallerDaemon.LogLevel.WARN, "Cleanup keyfile failed: %s", e.message);
                FileUtils.unlink (keyfile);
            }
        }
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

        log_message (InstallerDaemon.LogLevel.INFO, "Starting installation");

        var keyfile = "";

        try {
            var raw_squashfs = find_install_squashfs ();

            var repart_args = new GenericArray<string> ();

            configure_encryption (encrypt, encryption_password, repart_args, ref keyfile);

            status.step = InstallerDaemon.Step.PARTITION;
            status.percent = 10;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Wiping destination device");

            run ({"/usr/sbin/wipefs", "-a", dest_dev});

            on_log_message (InstallerDaemon.LogLevel.INFO, "Mounting squashfs: " + raw_squashfs);

            DirUtils.create_with_parents (SQUASH_MOUNT, 0755);

            log_message (InstallerDaemon.LogLevel.INFO, "Created squashfs mountpoint");

            run ({"mount", "-t", "squashfs", "-o", "loop,ro", raw_squashfs, SQUASH_MOUNT});

            log_message (InstallerDaemon.LogLevel.INFO, "Mounted squashfs");

            var raw_src = find_first_file (SQUASH_MOUNT, ".raw");
            if (raw_src == null) {
                throw new GLib.IOError.FAILED ("Could not locate raw image inside squashfs");
            }

            var repart_command = new GenericArray<string> ();

            repart_command.add ("systemd-repart");
            repart_command.add ("--copy-from=" + raw_src);
            repart_command.add ("--definitions=" + REPART_SRC);
            repart_command.add ("--dry-run=no");
            repart_command.add ("--empty=force");

            for (var i = 0; i < repart_args.length; i++) {
                repart_command.add (repart_args[i]);
            }

            repart_command.add (dest_dev);

            status.step = InstallerDaemon.Step.EXTRACT;
            status.percent = 20;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Running systemd-repart");

            run_capture (repart_command.data);

            status.percent = 80;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Running partprobe");

            run ({"partprobe", dest_dev});

            status.percent = 90;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Running udevadm settle");

            run ({"udevadm", "settle"});

            log_message (InstallerDaemon.LogLevel.INFO, "Completed!");

            cleanup (keyfile);

            status.step = InstallerDaemon.Step.BOOTLOADER;
            status.percent = 100;
            on_status (status);
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Installation aborted: " + e.message);
            cleanup (keyfile);
            throw new GLib.IOError.FAILED ("Installation aborted: " + e.message);
        }
    }

    private string get_contents (File file) {
        uint8[] contents;
        file.load_contents (null, out contents, null);
        return (string) contents;
    }

    public InstallerDaemon.PartitionTable bootloader_detect () throws GLib.Error {
        log_message (InstallerDaemon.LogLevel.ERROR, "Not implemented");
        throw new GLib.IOError.FAILED ("Not implemented");
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
            var sys_block = File.new_for_path ("/sys/block");
            var enumerator = sys_block.enumerate_children (
                FileAttribute.STANDARD_NAME,
                FileQueryInfoFlags.NONE
            );

            FileInfo info;
            while ((info = enumerator.next_file ()) != null) {
                var name = info.get_name ();

                // We only want physical disks
                if (!sys_block.get_child (name).get_child ("device").query_exists () || name.has_prefix ("sr")) {
                    continue;
                }

                uint64 size;
                uint64 sector_size;
                bool rotational;
                bool removable;

                uint64.try_parse (get_contents (sys_block.get_child (name).get_child ("size")).strip (), out size);
                uint64.try_parse (get_contents (sys_block.get_child (name).get_child ("queue").get_child ("logical_block_size")).strip (), out sector_size);
                bool.try_parse (get_contents (sys_block.get_child (name).get_child ("queue").get_child ("rotational")).strip (), out rotational);
                bool.try_parse (get_contents (sys_block.get_child (name).get_child ("removable")).strip (), out removable);

                physical_disks += Disk () {
                    name = name,
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

    public void set_demo_mode_locale (string locale) throws GLib.Error {
        GLib.FileUtils.set_contents ("/etc/default/locale", "LANG=" + locale);
    }

    public void trigger_demo_mode () throws GLib.Error {
        var demo_mode_file = GLib.File.new_for_path ("/var/lib/lightdm/demo-mode");
        try {
            demo_mode_file.create (GLib.FileCreateFlags.NONE);
        } catch (GLib.Error e) {
            if (!(e is GLib.IOError.EXISTS)) {
                throw e;
            }
        }
    }
}
