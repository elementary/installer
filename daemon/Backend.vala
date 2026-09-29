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
    protected static string? casper_dir () {
        const string CDROM = "/cdrom";
        try {
            var cdrom_dir = File.new_for_path (CDROM);
            var iter = cdrom_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            FileInfo info;
            while ((info = iter.next_file ()) != null) {
                unowned string name = info.get_name ();
                if (name.has_prefix ("casper")) {
                    return GLib.Path.build_filename (CDROM, name);
                }
            }
        } catch (GLib.Error e) {
            critical ("failed to find casper dir automatically: %s\n", e.message);
            return null;
        }
        return null;
    }

    public static DistinstBackend get_backend () {
        var casper_dir = casper_dir ();
        if (casper_dir == null) {
            return new InstallerDaemon.MkosiBackend ();
        }
        return new InstallerDaemon.DistinstBackend ();
    }
}
