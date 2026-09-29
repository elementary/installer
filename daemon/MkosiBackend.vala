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
public class InstallerDaemon.MkosiBackend : InstallerDaemon.DistinstBackend {
    private const string REPART_SRC = "/opt/repart-target";
    private const string SQUASH_MOUNT = "/mnt/source-image";

    private string? keyfile = null;
    private bool squash_mounted = false;

    private void run (string[] argv) throws GLib.Error {
        try {
            var launcher = new SubprocessLauncher (NONE);
            var process = launcher.spawnv (argv);
            process.wait_check ();
        } catch (GLib.Error e) {
            throw new IOError.FAILED ("Command failed: %s: %s", string.joinv (" ", argv), e.message);
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

    private void configure_encryption (bool encrypt, string password, GenericArray<string> repart_args) throws GLib.Error {
        if (!encrypt) {
            message ("No encryption");
            set_repart_encryption ("off");
            return;
        }

        if (has_tpm2 ()) {
            message ("TPM2 encryption");
            set_repart_encryption ("tpm2");
            return;
        }

        message ("Password encryption");
        set_repart_encryption ("key-file");
        int fd = FileUtils.open_tmp ("elementary-key-file-XXXXXX", out keyfile);
        if (fd < 0) {
            throw new IOError.FAILED ("Could not create encryption key file");
        }
        Posix.fchmod (fd, 0600);
        var stream = FileStream.fdopen (fd, "w");
        if (stream == null) {
            Posix.close (fd);
            throw new IOError.FAILED ("Could not open encryption key file");
        }
        stream.puts (password);
        stream.flush ();
        repart_args.add ("--key-file=" + keyfile);
    }

    private void cleanup () {
        message ("Cleanup");
        if (squash_mounted) {
            try {
                run ({"umount", SQUASH_MOUNT});
            } catch (GLib.Error e) {
                warning ("cleanup failed: %s", e.message);
            }
        }
        Posix.rmdir (SQUASH_MOUNT);
        if (keyfile != null) {
            try {
                run ({"shred", "-u", keyfile});
            } catch (GLib.Error e) {
                warning ("cleanup failed: %s", e.message);
                FileUtils.unlink (keyfile);
            }
        }
    }

    public override void install_with_default_disk_layout (InstallConfig config, string disk, bool encrypt, string encryption_password) throws GLib.Error {
        InstallerDaemon.LogLevel level = InstallerDaemon.LogLevel.INFO;
        on_log_message (level, "Clean install to " + disk);
        install (disk, encrypt, encryption_password);
    }

    public override void install_with_custom_disk_layout (InstallConfig config, Mount[] disk_config, LuksCredentials[] credentials) throws GLib.Error {
        InstallerDaemon.LogLevel level = InstallerDaemon.LogLevel.INFO;
        on_log_message (level, "Custom installations unsupported");
        throw new IOError.FAILED ("Custom installations unsupported");
    }

    private void install (string dest_dev, bool encrypt, string encryption_password) {
        InstallerDaemon.Status status = new InstallerDaemon.Status ();
        status.percent = 90;
        status.step = InstallerDaemon.Step.INIT;
        on_status (status);
        InstallerDaemon.LogLevel level = InstallerDaemon.LogLevel.INFO;
        on_log_message (level, "Starting installation!");

        try {
            var raw_squashfs = find_install_squashfs ();
            if (raw_squashfs == null) {
                on_log_message (level, "No .raw.squashfs file found.");
                throw new IOError.FAILED ("No .raw.squashfs file found.");
            }
            var repart_args = new GenericArray<string> ();
            configure_encryption (encrypt, encryption_password, repart_args);
            status.step = InstallerDaemon.Step.PARTITION;
            on_status (status);
            on_log_message (level, "Wiping destination device");
            run ({"/usr/sbin/wipefs", "-a", dest_dev});
            on_log_message (level, "Mounting squashfs: " + raw_squashfs);
            DirUtils.create_with_parents (SQUASH_MOUNT, 0755);
            on_log_message (level, "Created squashfs mountpoint");
            run ({"mount", "-t", "squashfs", "-o", "loop,ro", raw_squashfs, SQUASH_MOUNT});
            on_log_message (level, "Mounted squashfs");
            squash_mounted = true;
            var raw_src = find_first_file (SQUASH_MOUNT, ".raw");
            if (raw_src == null) {
                on_log_message (level, "Could not locate raw image inside squashfs");
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
            on_status (status);
            on_log_message (level, "Running systemd-repart");
            run_capture (repart_command.data);
            on_log_message (level, "Running partprobe");
            run ({"partprobe", dest_dev});
            on_log_message (level, "Running udevadm settle");
            run ({"udevadm", "settle"});
            on_log_message (level, "Completed!");
            cleanup ();
            status.step = InstallerDaemon.Step.BOOTLOADER;
            status.percent = 100;
            on_status (status);
        } catch (GLib.Error e) {
            on_log_message (level, "Installation aborted: " + e.message);
            cleanup ();
            throw new IOError.FAILED ("Installation aborted: %s", e.message);
        }
    }
}
