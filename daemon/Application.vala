private static GLib.MainLoop loop;

[DBus (name = "io.elementary.InstallerDaemon")]
public class InstallerDaemon.Application : GLib.Object {
    public signal void on_log_message (Distinst.LogLevel level, string message);
    public signal void on_status (Distinst.Status status);
    public signal void on_error (Distinst.Error error);

    private Distinst.Disks disks;

    construct {
        Distinst.log ((level, message) => {
            Idle.add (() => {
                on_log_message (level, message);
            });
        });
    }

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
        if (disk == null) {
            throw new GLib.IOError.NOT_FOUND ("Couldn't find a logical device with that name");
        }

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

    public void install_with_default_disk_layout (InstallConfig config, string disk, bool encrypt, string encryption_password) throws GLib.Error {
        var disks = new Distinst.Disks ();
        if (!default_disk_configuration (disks, disk, encrypt ? encryption_password : null)) {
            // TODO: Signal an error
        }

        install (config, (owned) disks);
    }

    public void install_with_custom_disk_layout (InstallConfig config, Mount[] disk_config, LuksCredentials[] credentials) throws GLib.Error {
        var disks = new Distinst.Disks ();
        if (!custom_disk_configuration (disks, disk_config, credentials)) {
            // TODO: Signal an error
        }

        install (config, (owned) disks);
    }

    private void install (InstallConfig config, owned Distinst.Disks disks) {
        var installer = new Distinst.Installer ();
        installer.on_error ((error) => on_error (error));
        installer.on_status ((status) => on_status (status));

        var distinst_config = Distinst.Config ();
        distinst_config.flags = config.flags;
        distinst_config.hostname = config.hostname;

        var casper = casper_dir ();
        distinst_config.remove = GLib.Path.build_filename (casper, "filesystem.manifest-remove");
        distinst_config.squashfs = GLib.Path.build_filename (casper, "filesystem.squashfs");

        debug ("language: %s\n", config.lang);
        distinst_config.lang = config.lang;

        distinst_config.keyboard_layout = config.keyboard_layout;
        distinst_config.keyboard_model = null;
        distinst_config.keyboard_variant = config.keyboard_variant == "" ? null : config.keyboard_variant;

        new Thread<void*> (null, () => {
            installer.install ((owned) disks, distinst_config);
            return null;
        });
    }

    private string casper_dir () {
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
        }

        return GLib.Path.build_filename (CDROM, "casper");
    }

    private bool default_disk_configuration (Distinst.Disks disks, string disk_path, string? encryption_password) {
        var encrypted_vg = Distinst.generate_unique_id ("cryptdata");
        var root_vg = Distinst.generate_unique_id ("data");
        if (encrypted_vg == null || root_vg == null) {
            critical ("unable to generate unique volume group IDs");
            return false;
        }

        Distinst.LvmEncryption? encryption;
        if (encryption_password != null) {
            debug ("encrypting");
            encryption = Distinst.LvmEncryption () {
                physical_volume = encrypted_vg,
                password = encryption_password,
                keydata = null
            };
        } else {
            debug ("not encrypting");
            encryption = null;
        }

        debug ("disk: %s\n", disk_path);
        var disk = new Distinst.Disk (disk_path);
        if (disk == null) {
            critical ("could not find %s", disk_path);
            return false;
        }

        var bootloader = Distinst.bootloader_detect ();

        var start_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.START,
            value = 0
        };

        // 256 MiB is the minimum distinst ESP partition size, so this is 256 MiB in MB plus a bit
        // extra for safety
        var efi_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE,
            value = 278
        };

        // 512MB /boot partition that's created if we're doing encryption
        var boot_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE,
            value = efi_sector.value + 512
        };

        // 4GB swap partition at the end
        var swap_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE_FROM_END,
            value = 4096
        };

        var end_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.END,
            value = 0
        };

        // Prepares a new partition table.
        int result = disk.mklabel (bootloader);

        if (result != 0) {
            critical ("unable to write partition table to %s", disk_path);
            return false;
        }

        var start = disk.get_sector (ref start_sector);
        var end = disk.get_sector (ref boot_sector);

        switch (bootloader) {
            case Distinst.PartitionTable.MSDOS:
                // This is used to ensure LVM installs will work with BIOS
                result = disk.add_partition (
                    new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.EXT4)
                        .partition_type (Distinst.PartitionType.PRIMARY)
                        .flag (Distinst.PartitionFlag.BOOT)
                        .mount ("/boot")
                );

                if (result != 0) {
                    critical ("unable to add boot partition to %s", disk_path);
                    return false;
                }

                break;
            case Distinst.PartitionTable.GPT:
                end = disk.get_sector (ref efi_sector);

                // A FAT32 partition is required for EFI installs
                result = disk.add_partition (
                    new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.FAT32)
                        .partition_type (Distinst.PartitionType.PRIMARY)
                        .flag (Distinst.PartitionFlag.ESP)
                        .mount ("/boot/efi")
                );

                if (result != 0) {
                    critical ("unable to add EFI partition to %s", disk_path);
                    return false;
                }

                // If we're encrypting, we need an unencrypted partition to store kernels and initramfs images
                if (encryption != null) {
                    start = disk.get_sector (ref efi_sector);
                    end = disk.get_sector (ref boot_sector);

                    result = disk.add_partition (
                        new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.EXT4)
                            .partition_type (Distinst.PartitionType.PRIMARY)
                            .mount ("/boot")
                    );

                    if (result != 0) {
                        critical ("unable to add /boot partition to %s", disk_path);
                        return false;
                    }
                }

                break;
        }

        // Start the LVM from the end of the /boot partition if we have encryption enabled
        if (encryption != null) {
            start = disk.get_sector (ref boot_sector);
        } else {
            start = disk.get_sector (ref efi_sector);
        }

        end = disk.get_sector (ref end_sector);

        result = disk.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.LVM)
                .partition_type (Distinst.PartitionType.PRIMARY)
                .logical_volume (root_vg, encryption)
        );

        if (result != 0) {
            critical ("unable to add lvm partition to %s", disk_path);
            return false;
        }

        disks.push ((owned) disk);

        result = disks.initialize_volume_groups ();

        if (result != 0) {
            critical ("unable to initialize volume groups on %s", disk_path);
            return false;
        }

        unowned Distinst.LvmDevice lvm_device = disks.get_logical_device (root_vg);

        if (lvm_device == null) {
            critical ("unable to find '%s' volume group on %s", root_vg, disk_path);
            return false;
        }

        start = lvm_device.get_sector (ref start_sector);
        end = lvm_device.get_sector (ref swap_sector);

        result = lvm_device.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.EXT4)
                .name ("root")
                .mount ("/")
        );

        if (result != 0) {
            critical ("unable to add / partition to lvm on %s", disk_path);
            return false;
        }

        start = lvm_device.get_sector (ref swap_sector);
        end = lvm_device.get_sector (ref end_sector);

        result = lvm_device.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.SWAP)
                .name ("swap")
        );

        if (result != 0) {
            critical ("unable to add swap partition to lvm on %s", disk_path);
            return false;
        }

        return true;
    }

    private bool custom_disk_configuration (Distinst.Disks disks, Mount[] mounts, LuksCredentials[] credentials) {
        Mount[] lvm_devices = {};

        foreach (Mount m in mounts) {
            if (m.is_lvm ()) {
                lvm_devices += m;
            } else {
                unowned Distinst.Disk disk = disks.get_physical_device (m.parent_disk);
                if (disk == null) {
                    var new_disk = new Distinst.Disk (m.parent_disk);
                    if (new_disk == null) {
                        warning ("could not find physical device: '%s'\n", m.parent_disk);
                        return false;
                    }

                    disks.push ((owned) new_disk);
                    disk = disks.get_physical_device (m.parent_disk);
                }

                unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

                if (partition == null) {
                    warning ("could not find %s\n", m.partition_path);
                    return false;
                }

                if (m.mount_point == "/boot/efi") {
                    if (m.is_valid_boot_mount ()) {
                        if (m.should_format ()) {
                            partition.format_with (m.filesystem);
                        }

                        partition.set_mount (m.mount_point);
                        partition.set_flags ({ Distinst.PartitionFlag.ESP });
                    } else {
                        warning ("unreachable code path -- efi partition is invalid\n");
                        return false;
                    }
                } else {
                    if (m.filesystem != Distinst.FileSystem.SWAP) {
                        partition.set_mount (m.mount_point);
                    }

                    if (m.mount_point == "/boot") {
                        partition.set_flags ({ Distinst.PartitionFlag.BOOT });
                    }

                    if (m.should_format ()) {
                        partition.format_with (m.filesystem);
                    }
                }
            }
        }

        disks.initialize_volume_groups ();

        foreach (LuksCredentials cred in credentials) {
            disks.decrypt_partition (cred.device, Distinst.LvmEncryption () {
                physical_volume = cred.pv,
                password = cred.password,
                keydata = null
            });
        }

        foreach (Mount m in lvm_devices) {
            var vg = m.parent_disk.offset (12);
            unowned Distinst.LvmDevice disk = disks.get_logical_device (vg);
            if (disk == null) {
                warning ("could not find %s\n", vg);
                return false;
            }

            unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

            if (partition == null) {
                warning ("could not find %s\n", m.partition_path);
                return false;
            }

            if (m.filesystem != Distinst.FileSystem.SWAP) {
                partition.set_mount (m.mount_point);
            }

            if (m.should_format ()) {
                partition.format_and_keep_name (m.filesystem);
            }
        }

        return true;
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