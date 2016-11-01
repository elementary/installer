// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Installer.Partition : GLib.Object {
    private GLib.ObjectPath dbus_path;
    private UDisks2.Block _block;
    private UDisks2.Block block {
        get {
            if (_block == null) {
                try {
                    _block = Bus.get_proxy_sync (BusType.SYSTEM, UDisks2.DBUS_NAME, dbus_path);
                } catch (Error e) {
                    critical (e.message);
                }
            }

            return _block;
        }
    }

    private UDisks2.Partition _partition;
    private UDisks2.Partition partition {
        get {
            if (_partition == null) {
                try {
                    _partition = Bus.get_proxy_sync (BusType.SYSTEM, UDisks2.DBUS_NAME, dbus_path);
                } catch (Error e) {
                    critical (e.message);
                }
            }

            return _partition;
        }
    }

    private UDisks2.Filesystem _filesystem;
    private UDisks2.Filesystem filesystem {
        get {
            if (_filesystem == null) {
                try {
                    _filesystem = Bus.get_proxy_sync (BusType.SYSTEM, UDisks2.DBUS_NAME, dbus_path);
                } catch (Error e) {
                    critical (e.message);
                }
            }

            return _filesystem;
        }
    }

    public Partition (GLib.ObjectPath dbus_path) {
        this.dbus_path = dbus_path;
    }

    public async GLib.ObjectPath get_disk_object_path () {
        if (_block == null) {
            try {
                _block = yield Bus.get_proxy (BusType.SYSTEM, UDisks2.DBUS_NAME, dbus_path);
            } catch (Error e) {
                critical (e.message);
            }
        }

        return block.drive;
    }

    public uint64 get_size () {
        return partition.size;
    }

    public async bool detect_operating_system (out string name, out string? version, out GLib.Icon icon) {
        bool software_mounted = false;
        string mount_point;
        if (_filesystem == null) {
            try {
                _filesystem = yield Bus.get_proxy (BusType.SYSTEM, UDisks2.DBUS_NAME, dbus_path);
            } catch (Error e) {
                critical (e.message);
            }
        }

        if (filesystem.mount_points == null || filesystem.mount_points.length[0] == 0) {
            var mount_options = new GLib.HashTable<string, GLib.Variant> (str_hash, str_equal);
            mount_options.set ("options", new GLib.Variant.string ("ro"));
            try {
                mount_point = filesystem.mount (mount_options);
                software_mounted = true;
            } catch (Error e) {
                critical (e.message);
                name = "";
                version = null;
                icon = null;
                return false;
            }
        } else {
            // If it's already mounted then the mount point is available (not as a string…)
            var builder = new StringBuilder ();
            foreach (var character in filesystem.mount_points) {
                builder.append_unichar (character);
            }

            mount_point = builder.str;
        }

        bool detected = yield Utils.detect_system (GLib.File.new_for_path (mount_point), out name, out version, out icon);

        if (software_mounted) {
            var unmount_options = new GLib.HashTable<string, GLib.Variant> (str_hash, str_equal);
            unmount_options.set ("force", new GLib.Variant.boolean (true));
            try {
                filesystem.unmount (unmount_options);
            } catch (Error e) {
                critical (e.message);
            }
        }

        return detected;
    }
}
