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
public class InstallerDaemon.Backend : GLib.Object {
    protected static string? find_first_file (string directory, string suffix) {
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
            warning ("%s", e.message);
        }
        return null;
    }

    protected static string? find_install_medium () {
        try {
            var output = run_capture ({"findmnt", "-rn", "-t", "iso9660,udf", "-o", "TARGET"});
            foreach (var line in output.split ("\n")) {
                var target = line.strip ();
                if (target != "") {
                    return target;
                }
            }
        } catch (GLib.Error e) {
            warning ("Could not locate installation medium: %s", e.message);
        }
        return null;
    }

    protected static string run_capture (string[] argv) throws GLib.Error {
        var process = new Subprocess.newv (argv, STDOUT_PIPE | STDERR_SILENCE);
        string stdout_buf;
        string stderr_buf;
        process.communicate_utf8 (null, null, out stdout_buf, out stderr_buf);
        if (!process.get_successful ()) {
            throw new IOError.FAILED ("Command failed: %s", argv[0]);
        }
        return stdout_buf.strip ();
    }

    public bool detected_mkosi_build {
        get {
            return is_mkosi_build ();
        }
    }

    protected static bool is_mkosi_build () {
        var medium = find_install_medium ();
        if (medium == null) {
            return false;
        }
        var extra = Path.build_filename (medium, "extra");
        var raw_squashfs = find_first_file (extra, ".raw.squashfs");
        if (raw_squashfs == null) {
            return false;
        }
        return true;
    }

    public static DistinstBackend get_backend () {
        if (is_mkosi_build ()) {
            message ("Using MKOSI backend");
            return new InstallerDaemon.MkosiBackend ();
        }
        message ("Using DISTINST backend");
        return new InstallerDaemon.DistinstBackend ();
    }
}
