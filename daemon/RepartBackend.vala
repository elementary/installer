/*
 * Copyright 2021 elementary, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[DBus (name = "io.elementary.InstallerDaemon")]
public class InstallerDaemon.RepartBackend : GLib.Object {
    private const string REPART_SRC = "/opt/repart-target";
    private const string SQUASH_MOUNT = "/mnt/source-image";

    public signal void on_log_message (InstallerDaemon.LogLevel level, string message);
    public signal void on_status (InstallerDaemon.Status status);
    public signal void on_error (InstallerDaemon.Error error);

    private string? keyfile = null;
    private bool squash_mounted = false;

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
                error (msg);
                break;
            default:
                message (msg);
                break;
        }
    }

    private string? find_first_file (string directory, string suffix) {
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

    private string? find_install_squashfs () {
        try {
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
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.WARN, "Could not find install squashfs medium: %s", e.message);
        }
        return null;
    }

    private string run_capture (string[] argv) throws GLib.Error {
        var process = new Subprocess.newv (argv, STDOUT_PIPE | STDERR_PIPE);
        string stdout_buf;
        string stderr_buf;
        process.communicate_utf8 (null, null, out stdout_buf, out stderr_buf);
        if (!process.get_successful ()) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Run command failed: %s: %s", string.joinv (" ", argv), stderr_buf.strip ());
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
        string contents;
        FileUtils.get_contents (path, out contents);
        var regex = new Regex ("^Encrypt=.*$", MULTILINE);
        contents = regex.replace (contents, contents.length, 0, "Encrypt=" + value);
        FileUtils.set_contents (path, contents);
    }

    private void configure_encryption (bool encrypt, string? password, GenericArray<string> repart_args) throws GLib.Error {
        if (!encrypt) {
            log_message (InstallerDaemon.LogLevel.INFO, "No encryption");
            set_repart_encryption ("off");
            return;
        }

        if (has_tpm2 () && (password == null || password.length == 0)) {
            log_message (InstallerDaemon.LogLevel.INFO, "TPM2 encryption");
            set_repart_encryption ("tpm2");
            return;
        }

        message ("Password encryption");
        set_repart_encryption ("key-file");
        int fd = FileUtils.open_tmp ("elementary-key-file-XXXXXX", out keyfile);
        if (fd < 0) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Could not create encryption key file");
        }
        Posix.fchmod (fd, 0600);
        var stream = FileStream.fdopen (fd, "w");
        if (stream == null) {
            Posix.close (fd);
            error ("Could not open encryption key file");
        }
        stream.puts (password);
        stream.flush ();
        repart_args.add ("--key-file=" + keyfile);
    }

    private void cleanup () {
        log_message (InstallerDaemon.LogLevel.INFO, "Cleanup");
        if (squash_mounted) {
            try {
                run ({"umount", SQUASH_MOUNT});
            } catch (GLib.Error e) {
                log_message (InstallerDaemon.LogLevel.WARN, "Cleanup failed: %s", e.message);
            }
        }
        Posix.rmdir (SQUASH_MOUNT);
        if (keyfile != null) {
            try {
                run ({"shred", "-u", keyfile});
            } catch (GLib.Error e) {
                log_message (InstallerDaemon.LogLevel.WARN, "Cleanup failed: %s", e.message);
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
        error ("Custom installations unsupported");
    }

    private void install (string dest_dev, bool encrypt, string? encryption_password) {
        InstallerDaemon.Status status = new InstallerDaemon.Status ();
        status.step = InstallerDaemon.Step.INIT;
        status.percent = 0;
        on_status (status);
        log_message (InstallerDaemon.LogLevel.INFO, "Starting installation");

        try {
            var raw_squashfs = find_install_squashfs ();
            if (raw_squashfs == null) {
                log_message (InstallerDaemon.LogLevel.ERROR, "No .raw.squashfs file found.");
                error ("No .raw.squashfs file found.");
            }
            var repart_args = new GenericArray<string> ();
            configure_encryption (encrypt, encryption_password, repart_args);
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
            squash_mounted = true;
            var raw_src = find_first_file (SQUASH_MOUNT, ".raw");
            if (raw_src == null) {
                log_message (InstallerDaemon.LogLevel.INFO, "Could not locate raw image inside squashfs");
                throw new IOError.NOT_FOUND ("Could not locate raw image inside squashfs");
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
            cleanup ();
            status.step = InstallerDaemon.Step.BOOTLOADER;
            status.percent = 100;
            on_status (status);
        } catch (GLib.Error e) {
            log_message (InstallerDaemon.LogLevel.ERROR, "Installation aborted: " + e.message);
            cleanup ();
        }
    }
}
