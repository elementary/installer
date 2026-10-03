/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[DBus (name = "io.elementary.InstallerDaemon")]
public class InstallerDaemon.RepartBackend : InstallerInterface, GLib.Object {
    private const string REPART_SRC = "/opt/repart-target";

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

    private string? find_unique_file (string directory, string suffix) throws GLib.Error {
        string? result = null;
        try {
            var dir = File.new_for_path (directory);
            var enumerator = dir.enumerate_children (
                FileAttribute.STANDARD_NAME + "," +
                FileAttribute.STANDARD_TYPE,
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS
            );

            FileInfo? info;
            while ((info = enumerator.next_file ()) != null) {
                var name = info.get_name ();
                if (name.has_suffix (suffix)) {
                    if (info.get_file_type () != FileType.REGULAR || result != null) {
                        throw new GLib.IOError.FAILED ("Expected a single regular %s file in %s", suffix, directory);
                    }
                    result = Path.build_filename (directory, name);
                }
            }
        } catch (GLib.Error e) {
            if (!(e is GLib.IOError.NOT_FOUND)) {
                throw e;
            }
        }
        return result;
    }

    private string find_install_squashfs () throws GLib.Error {
        var output = run_capture ({"findmnt", "-rn", "-t", "iso9660,udf", "-o", "TARGET"});
        string? result = null;
        foreach (var line in output.split ("\n")) {
            var target = line.strip ();
            if (target == "") {
                continue;
            }

            var extra = Path.build_filename (target, "extra");
            var raw_squashfs = find_unique_file (extra, ".raw.squashfs");
            if (raw_squashfs != null) {
                if (result != null) {
                    throw new GLib.IOError.FAILED ("Multiple installation images found");
                }
                result = raw_squashfs;
            }
        }

        if (result == null) {
            throw new GLib.IOError.FAILED ("No .raw.squashfs file found.");
        }
        return result;
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
                stdout_buf.strip (),
                stderr_buf.strip ()
            );
        }

        return stdout_buf.strip ();
    }

    private void run (string[] argv) throws GLib.Error {
        try {
            var process = new Subprocess.newv (argv, NONE);
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

    private void set_repart_encryption (string definitions, string value) throws GLib.Error {
        var path = Path.build_filename (definitions, "40-root.conf");
        var info = File.new_for_path (path).query_info (
            FileAttribute.STANDARD_TYPE, FileQueryInfoFlags.NOFOLLOW_SYMLINKS
        );
        if (info.get_file_type () != FileType.REGULAR) {
            throw new GLib.IOError.FAILED ("Expected a regular root definition in %s", path);
        }
        string contents = "";

        FileUtils.get_contents (path, out contents);

        var regex = new Regex ("^Encrypt=.*$", MULTILINE);
        MatchInfo match;
        if (!regex.match (contents, 0, out match) || match.next ()) {
            throw new GLib.IOError.FAILED ("Expected exactly one Encrypt setting in %s", path);
        }
        contents = regex.replace (contents, contents.length, 0, "Encrypt=" + value);

        FileUtils.set_contents (path, contents);
    }

    private void configure_encryption (string work, string definitions, bool encrypt, string password, ref string[] repart_args, ref string keyfile) throws GLib.Error {
        if (!encrypt) {
            log_message (InstallerDaemon.LogLevel.INFO, "No encryption");
            set_repart_encryption (definitions, "off");
            return;
        }

        // The existing D-Bus API uses an empty password to request TPM-only encryption.
        if (password.length == 0) {
            if (!has_tpm2 ()) {
                throw new GLib.IOError.FAILED ("TPM2 encryption requested but no usable TPM2 is available");
            }
            log_message (InstallerDaemon.LogLevel.INFO, "TPM2 encryption");
            set_repart_encryption (definitions, "tpm2");
            return;
        }

        log_message (InstallerDaemon.LogLevel.INFO, "Password encryption");

        set_repart_encryption (definitions, "key-file");

        keyfile = Path.build_filename (work, "root.key");
        var stream = File.new_for_path (keyfile).create (FileCreateFlags.PRIVATE);
        GLib.Error? write_error = null;
        try {
            size_t written;
            stream.write_all (password.data, out written);
            stream.flush ();
        } catch (GLib.Error e) {
            write_error = e;
        }
        try {
            stream.close ();
        } catch (GLib.Error e) {
            if (write_error == null) {
                write_error = e;
            }
        }
        if (write_error != null) {
            throw write_error;
        }

        var args = repart_args;
        args += "--key-file=" + keyfile;
        repart_args = args;
    }

    private void cleanup (string work, string squash_mount, bool mounted, string keyfile) throws GLib.Error {
        log_message (InstallerDaemon.LogLevel.INFO, "Cleanup");
        GLib.Error? key_error = null;

        if (keyfile.length > 0) {
            try {
                File.new_for_path (keyfile).delete ();
            } catch (GLib.Error e) {
                if (!(e is GLib.IOError.NOT_FOUND)) {
                    key_error = e;
                }
            }
        }

        try {
            if (mounted) {
                // Never traverse the source mount if unmounting it failed.
                run ({"umount", squash_mount});
            }
            var definitions = File.new_for_path (Path.build_filename (work, "repart"));
            try {
                var enumerator = definitions.enumerate_children (
                    FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NOFOLLOW_SYMLINKS
                );
                FileInfo? info;
                while ((info = enumerator.next_file ()) != null) {
                    definitions.get_child (info.get_name ()).delete ();
                }
                enumerator.close ();
                definitions.delete ();
            } catch (GLib.Error e) {
                if (!(e is GLib.IOError.NOT_FOUND)) {
                    throw e;
                }
            }
            try {
                File.new_for_path (squash_mount).delete ();
            } catch (GLib.Error e) {
                if (!(e is GLib.IOError.NOT_FOUND)) {
                    throw e;
                }
            }
            File.new_for_path (work).delete ();
        } catch (GLib.Error e) {
            if (key_error != null) {
                log_message (InstallerDaemon.LogLevel.WARN, "Cleanup keyfile failed: %s", key_error.message);
            }
            throw e;
        }
        if (key_error != null) {
            throw key_error;
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
        var work = DirUtils.mkdtemp ("/run/elementary-installer-XXXXXX");
        if (work == null) {
            throw new GLib.IOError.FAILED ("Could not create private installation directory");
        }
        var squash_mount = Path.build_filename (work, "source");
        var definitions = Path.build_filename (work, "repart");
        bool mounted = false;

        try {
            var raw_squashfs = find_install_squashfs ();

            File.new_for_path (squash_mount).make_directory ();
            File.new_for_path (definitions).make_directory ();
            // Repart definitions are a flat directory of files (including masks).
            var source_definitions = File.new_for_path (REPART_SRC);
            var enumerator = source_definitions.enumerate_children (
                FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS
            );
            FileInfo? info;
            while ((info = enumerator.next_file ()) != null) {
                if (info.get_file_type () != FileType.REGULAR && info.get_file_type () != FileType.SYMBOLIC_LINK) {
                    throw new GLib.IOError.FAILED ("Unsupported repart definition: %s", info.get_name ());
                }
                source_definitions.get_child (info.get_name ()).copy (
                    File.new_for_path (Path.build_filename (definitions, info.get_name ())),
                    FileCopyFlags.NOFOLLOW_SYMLINKS
                );
            }
            enumerator.close ();

            string[] repart_args = {};

            configure_encryption (work, definitions, encrypt, encryption_password, ref repart_args, ref keyfile);

            on_log_message (InstallerDaemon.LogLevel.INFO, "Mounting squashfs: " + raw_squashfs);

            run ({"mount", "-t", "squashfs", "-o", "loop,ro", raw_squashfs, squash_mount});
            mounted = true;

            log_message (InstallerDaemon.LogLevel.INFO, "Mounted squashfs");

            var raw_src = find_unique_file (squash_mount, ".raw");
            if (raw_src == null) {
                throw new GLib.IOError.FAILED ("Could not locate raw image inside squashfs");
            }

            string[] repart_command = {
                "systemd-repart",
                "--copy-from=" + raw_src,
                "--definitions=" + definitions,
                "--dry-run=yes",
                "--empty=force"
            };

            foreach (var repart_arg in repart_args) {
                repart_command += repart_arg;
            }

            repart_command += dest_dev;

            log_message (InstallerDaemon.LogLevel.INFO, "Validating systemd-repart plan");
            run_capture (repart_command);

            status.step = InstallerDaemon.Step.PARTITION;
            status.percent = 10;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Wiping destination device");
            run ({"/usr/sbin/wipefs", "-a", dest_dev});
            repart_command[3] = "--dry-run=no";

            status.step = InstallerDaemon.Step.EXTRACT;
            status.percent = 20;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Running systemd-repart");

            run_capture (repart_command);

            status.percent = 80;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Running partprobe");

            run ({"partprobe", dest_dev});

            status.percent = 90;
            on_status (status);

            log_message (InstallerDaemon.LogLevel.INFO, "Running udevadm settle");

            run ({"udevadm", "settle"});
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Installation aborted: " + e.message);
            try {
                cleanup (work, squash_mount, mounted, keyfile);
            } catch (GLib.Error cleanup_error) {
                log_message (InstallerDaemon.LogLevel.WARN, "Cleanup failed: %s", cleanup_error.message);
            }
            throw new GLib.IOError.FAILED ("Installation aborted: " + e.message);
        }

        cleanup (work, squash_mount, mounted, keyfile);
        log_message (InstallerDaemon.LogLevel.INFO, "Completed!");
        status.step = InstallerDaemon.Step.BOOTLOADER;
        status.percent = 100;
        on_status (status);
    }

    private string get_contents (File file) throws GLib.Error {
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
