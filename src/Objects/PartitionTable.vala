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

public class Installer.PartitionTable : GLib.Object {
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

    private UDisks2.PartitionTable _partition_table;
    private UDisks2.PartitionTable partition_table {
        get {
            if (_partition_table == null) {
                try {
                    _partition_table = Bus.get_proxy_sync (BusType.SYSTEM, UDisks2.DBUS_NAME, dbus_path);
                } catch (Error e) {
                    critical (e.message);
                }
            }

            return _partition_table;
        }
    }

    public PartitionTable (GLib.ObjectPath dbus_path) {
        this.dbus_path = dbus_path;
    }

    public string get_block_device () {
        return (string) block.device;
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
}
