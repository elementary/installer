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

public class Installer.Disk : GLib.Object {
    public PartitionTable partition_table;
    public Gee.LinkedList<Partition> partitions;
    private GLib.ObjectPath dbus_path;
    private UDisks2.Drive _drive = null;
    private UDisks2.Drive drive {
        get {
            if (_drive == null) {
                try {
                    _drive = Bus.get_proxy_sync (BusType.SYSTEM, UDisks2.DBUS_NAME, dbus_path);
                } catch (Error e) {
                    critical (e.message);
                }
            }

            return _drive;
        }
    }

    private static Gee.LinkedList<Disk> disk_list;
    public static async Gee.LinkedList<Disk> get_disks () {
        if (disk_list != null) {
            return disk_list;
        }

        disk_list = new Gee.LinkedList<Disk> ();
        var partition_list = new Gee.LinkedList<Partition> ();
        var partition_table_list = new Gee.LinkedList<PartitionTable> ();
        DBusObjectManagerClient client = null;
        try {
            client = yield DBusObjectManagerClient.new_for_bus (BusType.SYSTEM, GLib.DBusObjectManagerClientFlags.NONE,
                                                            "org.freedesktop.UDisks2", "/org/freedesktop/UDisks2", null);
        } catch (Error e) {
            critical (e.message);
            return disk_list;
        }

        foreach (unowned GLib.DBusObject object in client.get_objects ()) {
            if (object.get_interface ("org.freedesktop.UDisks2.Drive") != null) {
                var disk = new Installer.Disk ((GLib.ObjectPath) object.get_object_path ());
                disk_list.add (disk);
            } else {
                if (object.get_interface ("org.freedesktop.UDisks2.Block") != null) {
                    if (object.get_interface ("org.freedesktop.UDisks2.Partition") != null && object.get_interface ("org.freedesktop.UDisks2.Filesystem") != null) {
                        var partition = new Installer.Partition ((GLib.ObjectPath) object.get_object_path ());
                        partition_list.add (partition);
                    } else if (object.get_interface ("org.freedesktop.UDisks2.PartitionTable") != null) {
                        var partition_table = new Installer.PartitionTable ((GLib.ObjectPath) object.get_object_path ());
                        partition_table_list.add (partition_table);
                    }
                }
            }
        }

        foreach (var disk in disk_list) {
            yield disk.insert_own_partitions (partition_list);
            yield disk.insert_own_partition_table (partition_table_list);
        }

        return disk_list;
    }

    public Disk (GLib.ObjectPath dbus_path) {
        this.dbus_path = dbus_path;
    }

    construct {
        partitions = new Gee.LinkedList<Partition> ();
    }

    public string get_id () {
        return drive.id;
    }

    public string get_label_name () {
        return drive.model.replace ("_", " ");
    }

    public uint64 get_size () {
        return drive.size;
    }

    // Get the partitions from the list that are in this table.
    public async void insert_own_partitions (Gee.LinkedList<Partition> given_partitions) {
        foreach (var partition in given_partitions) {
            var partition_path = yield partition.get_disk_object_path ();
            if (partition_path == dbus_path) {
                partitions.insert (0, partition);
            }
        }

        given_partitions.remove_all (partitions);
    }

    // Get the partitions from the list that are in this table.
    public async void insert_own_partition_table (Gee.LinkedList<PartitionTable> given_partition_tables) {
        foreach (var partition_table in given_partition_tables) {
            var disk_path = yield partition_table.get_disk_object_path ();
            if (disk_path == dbus_path) {
                this.partition_table = partition_table;
            }
        }

        given_partition_tables.remove (partition_table);
    }
}
