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

    private int run (string[] argv) throws GLib.Error {
        var launcher = new SubprocessLauncher (NONE);
        var process = launcher.spawnv (argv);
        process.wait_check ();
        return 0;
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

    private void configure_encryption (string password, GenericArray<string> repart_args) throws GLib.Error {
        if (password == null) {
            set_repart_encryption ("off");
        } else if (has_tpm2 ()) {
            set_repart_encryption ("tpm2");
        } else {
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
    }

    private void cleanup () {
        if (squash_mounted) {
            try {
                run ({"umount", SQUASH_MOUNT});
            } catch (GLib.Error e) {
            }
        }
        Posix.rmdir (SQUASH_MOUNT);
        if (keyfile != null) {
            try {
                run ({"shred", "-u", keyfile});
            } catch (GLib.Error e) {
                FileUtils.unlink (keyfile);
            }
        }
    }

    public override void install_with_default_disk_layout (InstallConfig config, string disk, bool encrypt, string encryption_password) throws GLib.Error {
        install (disk, encrypt ? encryption_password : null);
    }

    public override void install_with_custom_disk_layout (InstallConfig config, Mount[] disk_config, LuksCredentials[] credentials) throws GLib.Error {
        throw new IOError.FAILED ("Custom installations unsupported");
    }

    private void install (string dest_dev, string encryption_password) {
        try {
            var medium = find_install_medium ();
            if (medium == null) {
                throw new IOError.FAILED ("Could not locate installation medium.");
            }
            var extra = Path.build_filename (medium, "extra");
            var raw_squashfs = find_first_file (extra, ".raw.squashfs");
            if (raw_squashfs == null) {
                throw new IOError.FAILED ("No .raw.squashfs file found.");
            }
            var repart_args = new GenericArray<string> ();
            configure_encryption (encryption_password, repart_args);
            run ({"/usr/sbin/wipefs", "-a", dest_dev});
            DirUtils.create_with_parents (SQUASH_MOUNT, 0755);
            run ({"mount", "-t", "squashfs", "-o", "loop,ro", raw_squashfs, SQUASH_MOUNT});
            squash_mounted = true;
            var raw_src = find_first_file (SQUASH_MOUNT, ".raw");
            if (raw_src == null) {
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
            run (repart_command.data);
            run ({"partprobe", dest_dev});
            run ({"udevadm", "settle"});
            cleanup ();
        } catch (GLib.Error e) {
            critical ("Installation aborted: %s", e.message);
            cleanup ();
        }
    }
}
