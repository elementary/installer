private static GLib.MainLoop loop;

[DBus (name = "io.elementary.InstallerDaemon")]
public class InstallerDaemon.Application : GLib.Object {
    public signal void on_log_message (string message);
    public signal void on_status (Distinst.Status status);
    public signal void on_error (Distinst.Error error);

    private Distinst.Disks disks;

    public Distinst.PartitionTable bootloader_detect () throws GLib.Error {
        return Distinst.bootloader_detect ();
    }

    public DiskInfo get_disks (bool get_partitions = false) throws GLib.Error {
        disks = Distinst.Disks.probe ();

        if (get_partitions) {
            disks.initialize_volume_groups ();
        }

        DiskInfo result = DiskInfo ();

        Disk[] physical_disks = {};
        Disk[] logical_disks = {};

        foreach (unowned Distinst.Disk disk in disks.list ()) {
            // Skip root disk or live disk
            if (disk.contains_mount ("/", disks) || disk.contains_mount ("/cdrom", disks)) {
                continue;
            }

            Partition[] partitions = {};

            if (get_partitions) {
                foreach (unowned Distinst.Partition part in disk.list_partitions ()) {
                    string lvm_vg = (part.get_file_system () == Distinst.FileSystem.LVM)
                        ? string_from_utf8 (part.get_current_lvm_volume_group ())
                        : "";

                    partitions += Partition () {
                        device_path = string_from_utf8 (part.get_device_path ()),
                        filesystem = part.get_file_system (),
                        start_sector = part.get_start_sector (),
                        end_sector = part.get_end_sector (),
                        sectors_used = part.sectors_used (disk.get_sector_size ()),
                        current_lvm_volume_group = lvm_vg
                    };
                }
            }

            string model = string_from_utf8 (disk.get_model ());
            string name = model.length == 0 ? string_from_utf8 (disk.get_serial ()).replace ("_", " ") : model;

            physical_disks += Disk () {
                name = name,
                device_path = string_from_utf8 (disk.get_device_path ()),
                sectors = disk.get_sectors (),
                sector_size = disk.get_sector_size (),
                rotational = disk.is_rotational (),
                removable = disk.is_removable (),
                partitions = partitions
            };
        }

        if (get_partitions) {
            foreach (unowned Distinst.LvmDevice disk in disks.list_logical ()) {
                Partition[] partitions = {};

                foreach (unowned Distinst.Partition part in disk.list_partitions ()) {
                    string lvm_vg = (part.get_file_system () == Distinst.FileSystem.LVM)
                        ? string_from_utf8 (part.get_current_lvm_volume_group ())
                        : "";

                    partitions += Partition () {
                        device_path = string_from_utf8 (part.get_device_path ()),
                        filesystem = part.get_file_system (),
                        start_sector = part.get_start_sector (),
                        end_sector = part.get_end_sector (),
                        sectors_used = part.sectors_used (disk.get_sector_size ()),
                        current_lvm_volume_group = lvm_vg
                    };
                }

                logical_disks += Disk () {
                    name = string_from_utf8 (disk.get_model ()),
                    device_path = string_from_utf8 (disk.get_device_path ()),
                    sectors = disk.get_sectors (),
                    sector_size = disk.get_sector_size (),
                    partitions = partitions
                };
            }
        }

        result.physical_disks = physical_disks;
        result.logical_disks = logical_disks;
        return result;
    }

    public int decrypt_partition (string path, string pv, string password) throws GLib.Error {
        return disks.decrypt_partition (path, Distinst.LvmEncryption () {
            physical_volume = pv,
            password = password,
            keydata = null
        });
    }

    public Disk get_logical_device (string pv) throws GLib.Error {
        unowned Distinst.LvmDevice disk = disks.get_logical_device (pv);

        Partition[] partitions = {};

        foreach (unowned Distinst.Partition part in disk.list_partitions ()) {
            string lvm_vg = (part.get_file_system () == Distinst.FileSystem.LVM)
                ? string_from_utf8 (part.get_current_lvm_volume_group ())
                : "";

            partitions += Partition () {
                device_path = string_from_utf8 (part.get_device_path ()),
                filesystem = part.get_file_system (),
                start_sector = part.get_start_sector (),
                end_sector = part.get_end_sector (),
                sectors_used = part.sectors_used (disk.get_sector_size ()),
                current_lvm_volume_group = lvm_vg
            };
        }

        return Disk () {
            name = string_from_utf8 (disk.get_model ()),
            device_path = string_from_utf8 (disk.get_device_path ()),
            sectors = disk.get_sectors (),
            sector_size = disk.get_sector_size (),
            partitions = partitions
        };
    }

    private static string string_from_utf8 (uint8[] input) {
        var builder = new GLib.StringBuilder.sized (input.length);
        builder.append_len ((string) input, input.length);
        return (owned) builder.str;
    }
}

private void on_bus_acquired (GLib.DBusConnection connection, string name) {
    try {
        connection.register_object ("/io/elementary/InstallerDaemon", new InstallerDaemon.Application ());
    } catch (GLib.Error e) {
        critical ("Unable to register the object: %s", e.message);
    }
}

public static int main (string[] args) {
    loop = new GLib.MainLoop (null, false);

    var owner_id = GLib.Bus.own_name (
        GLib.BusType.SYSTEM,
        "io.elementary.InstallerDaemon",
        GLib.BusNameOwnerFlags.NONE,
        on_bus_acquired,
        () => { },
        () => { loop.quit (); }
    );

    loop.run ();

    GLib.Bus.unown_name (owner_id);

    return 0;
}
