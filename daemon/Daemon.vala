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

private static GLib.MainLoop loop;

[DBus (name = "io.elementary.InstallerDaemon")]
public class InstallerDaemon.Daemon : GLib.Object {
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

    public InstallerDaemon.PartitionTable bootloader_detect () throws GLib.Error {
        return to_common_usage_bootloader (Distinst.bootloader_detect ());
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
            if (disk.is_read_only ()) {
                continue;
            }

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
                        filesystem = to_common_fs (part.get_file_system ()),
                        start_sector = part.get_start_sector (),
                        end_sector = part.get_end_sector (),
                        sectors_used = to_common_usage (part.sectors_used (disk.get_sector_size ())),
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
                        filesystem = to_common_fs (part.get_file_system ()),
                        start_sector = part.get_start_sector (),
                        end_sector = part.get_end_sector (),
                        sectors_used = to_common_usage (part.sectors_used (disk.get_sector_size ())),
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
                filesystem = to_common_fs (part.get_file_system ()),
                start_sector = part.get_start_sector (),
                end_sector = part.get_end_sector (),
                sectors_used = to_common_usage (part.sectors_used (disk.get_sector_size ())),
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
        default_disk_configuration (disks, disk, encrypt ? encryption_password : null);

        install (config, (owned) disks);
    }

    public void install_with_custom_disk_layout (InstallConfig config, Mount[] disk_config, LuksCredentials[] credentials) throws GLib.Error {
        var disks = new Distinst.Disks ();
        custom_disk_configuration (disks, disk_config, credentials);

        install (config, (owned) disks);
    }

    private void install (InstallConfig config, owned Distinst.Disks disks) {
        var installer = new Distinst.Installer ();
        installer.on_error ((error) => on_error (error));
        installer.on_status ((status) => on_status (status));

        var distinst_config = Distinst.Config ();
        uint8 flags = 0;
        if (config.modify_boot_order) {
            flags = Distinst.MODIFY_BOOT_ORDER;
        }

        if (config.install_drivers) {
            flags |= Distinst.RUN_UBUNTU_DRIVERS;
        }

        distinst_config.flags = flags;
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
            if (installer.install ((owned) disks, distinst_config) != 0) {
                Idle.add (() => {
                    on_error (Distinst.Error ());
                    return GLib.Source.REMOVE;
                });
            }

            return null;
        });
    }

    public void set_demo_mode_locale (string locale) throws GLib.Error {
        GLib.FileUtils.set_contents ("/etc/default/locale", "LANG=" + locale);
    }

    public void trigger_demo_mode () throws GLib.Error {
        var demo_mode_file = GLib.File.new_for_path ("/var/lib/lightdm/demo-mode");
        try {
            demo_mode_file.create (GLib.FileCreateFlags.NONE);
        } catch (Error e) {
            if (!(e is GLib.IOError.EXISTS)) {
                throw e;
            }
        }
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

    private void default_disk_configuration (Distinst.Disks disks, string disk_path, string? encryption_password) throws GLib.IOError {
        var encrypted_vg = Distinst.generate_unique_id ("cryptdata");
        var root_vg = Distinst.generate_unique_id ("data");
        if (encrypted_vg == null || root_vg == null) {
            throw new GLib.IOError.FAILED ("Unable to generate unique volume group IDs");
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
            throw new GLib.IOError.FAILED ("Could not find %s", disk_path);
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

        // 1024MB /boot partition that's created if we're doing encryption
        var boot_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE,
            value = efi_sector.value + 1024
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
            throw new GLib.IOError.FAILED ("Unable to write partition table to %s", disk_path);
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
                    throw new GLib.IOError.FAILED ("Unable to add boot partition to %s", disk_path);
                }

                // Start the LVM from the end of our /boot partition
                start = disk.get_sector (ref boot_sector);
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
                    throw new GLib.IOError.FAILED ("Unable to add EFI partition to %s", disk_path);
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
                        throw new GLib.IOError.FAILED ("unable to add /boot partition to %s", disk_path);
                    }

                    // Start the LVM from the end of our /boot/efi and /boot partitions
                    start = disk.get_sector (ref boot_sector);
                } else {
                    // No encryption, we only have a /boot/efi partition, start the LVM from there
                    start = disk.get_sector (ref efi_sector);
                }

                break;
        }

        end = disk.get_sector (ref end_sector);

        result = disk.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.LVM)
                .partition_type (Distinst.PartitionType.PRIMARY)
                .logical_volume (root_vg, encryption)
        );

        if (result != 0) {
            throw new GLib.IOError.FAILED ("Unable to add LVM partition to %s", disk_path);
        }

        disks.push ((owned) disk);

        result = disks.initialize_volume_groups ();

        if (result != 0) {
            throw new GLib.IOError.FAILED ("Unable to initialize volume groups on %s", disk_path);
        }

        unowned Distinst.LvmDevice lvm_device = disks.get_logical_device (root_vg);

        if (lvm_device == null) {
            throw new GLib.IOError.FAILED ("Unable to find '%s' volume group on %s", root_vg, disk_path);
        }

        start = lvm_device.get_sector (ref start_sector);
        end = lvm_device.get_sector (ref swap_sector);

        result = lvm_device.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.EXT4)
                .name ("root")
                .mount ("/")
        );

        if (result != 0) {
            throw new GLib.IOError.FAILED ("Unable to add / partition to LVM on %s", disk_path);
        }

        start = lvm_device.get_sector (ref swap_sector);
        end = lvm_device.get_sector (ref end_sector);

        result = lvm_device.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystem.SWAP)
                .name ("swap")
        );

        if (result != 0) {
            throw new GLib.IOError.FAILED ("Unable to add swap partition to LVM on %s", disk_path);
        }
    }

    private void custom_disk_configuration (Distinst.Disks disks, Mount[] mounts, LuksCredentials[] credentials) throws GLib.IOError {
        Mount[] lvm_devices = {};

        foreach (Mount m in mounts) {
            if (m.is_lvm ()) {
                lvm_devices += m;
            } else {
                unowned Distinst.Disk disk = disks.get_physical_device (m.parent_disk);
                if (disk == null) {
                    var new_disk = new Distinst.Disk (m.parent_disk);
                    if (new_disk == null) {
                        throw new GLib.IOError.FAILED ("Could not find physical device: '%s'", m.parent_disk);
                    }

                    disks.push ((owned) new_disk);
                    disk = disks.get_physical_device (m.parent_disk);
                }

                unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

                if (partition == null) {
                    throw new GLib.IOError.FAILED ("Could not find %s", m.partition_path);
                }

                if (m.mount_point == "/boot/efi") {
                    if (m.is_valid_boot_mount ()) {
                        if (m.should_format ()) {
                            partition.format_with (to_distinst_fs (m.filesystem));
                        }

                        partition.set_mount (m.mount_point);
                        partition.set_flags ({ Distinst.PartitionFlag.ESP });
                    } else {
                        throw new GLib.IOError.FAILED ("Unreachable code path -- EFI partition is invalid");
                    }
                } else {
                    if (m.filesystem != InstallerDaemon.FileSystem.SWAP) {
                        partition.set_mount (m.mount_point);
                    }

                    if (m.mount_point == "/boot") {
                        partition.set_flags ({ Distinst.PartitionFlag.BOOT });
                    }

                    if (m.should_format ()) {
                        partition.format_with (to_distinst_fs (m.filesystem));
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
                throw new GLib.IOError.FAILED ("Could not find %s", vg);
            }

            unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

            if (partition == null) {
                throw new GLib.IOError.FAILED ("could not find %s", m.partition_path);
            }

            if (m.filesystem != InstallerDaemon.FileSystem.SWAP) {
                partition.set_mount (m.mount_point);
            }

            if (m.should_format ()) {
                partition.format_and_keep_name (to_distinst_fs (m.filesystem));
            }
        }
    }

    private static string string_from_utf8 (uint8[] input) {
        var builder = new GLib.StringBuilder.sized (input.length);
        builder.append_len ((string) input, input.length);
        return (owned) builder.str;
    }

    private InstallerDaemon.FileSystem to_common_fs (Distinst.FileSystem fs) {
        switch (fs) {
            case BTRFS:
                return InstallerDaemon.FileSystem.BTRFS;
            case EXT2:
                return InstallerDaemon.FileSystem.EXT2;
            case EXT3:
                return InstallerDaemon.FileSystem.EXT3;
            case EXT4:
                return InstallerDaemon.FileSystem.EXT4;
            case F2FS:
                return InstallerDaemon.FileSystem.F2FS;
            case FAT16:
                return InstallerDaemon.FileSystem.FAT16;
            case FAT32:
                return InstallerDaemon.FileSystem.FAT32;
            case NONE:
                return InstallerDaemon.FileSystem.NONE;
            case NTFS:
                return InstallerDaemon.FileSystem.NTFS;
            case SWAP:
                return InstallerDaemon.FileSystem.SWAP;
            case XFS:
                return InstallerDaemon.FileSystem.XFS;
            case LVM:
                return InstallerDaemon.FileSystem.LVM;
            case LUKS:
                return InstallerDaemon.FileSystem.LUKS;
            default:
                return InstallerDaemon.FileSystem.NONE;
        }
    }

    private InstallerDaemon.PartitionUsage to_common_usage (Distinst.PartitionUsage usage) {
        return InstallerDaemon.PartitionUsage () {
            tag = usage.tag,
            value = usage.value
        };
    }

    private Distinst.FileSystem to_distinst_fs (InstallerDaemon.FileSystem fs) {
        switch (fs) {
            case BTRFS:
                return Distinst.FileSystem.BTRFS;
            case EXT2:
                return Distinst.FileSystem.EXT2;
            case EXT3:
                return Distinst.FileSystem.EXT3;
            case EXT4:
                return Distinst.FileSystem.EXT4;
            case F2FS:
                return Distinst.FileSystem.F2FS;
            case FAT16:
                return Distinst.FileSystem.FAT16;
            case FAT32:
                return Distinst.FileSystem.FAT32;
            case NONE:
                return Distinst.FileSystem.NONE;
            case NTFS:
                return Distinst.FileSystem.NTFS;
            case SWAP:
                return Distinst.FileSystem.SWAP;
            case XFS:
                return Distinst.FileSystem.XFS;
            case LVM:
                return Distinst.FileSystem.LVM;
            case LUKS:
                return Distinst.FileSystem.LUKS;
            default:
                return Distinst.FileSystem.NONE;
        }
    }

    private InstallerDaemon.PartitionTable to_common_usage_bootloader (Distinst.PartitionTable bootloader) {
        switch (bootloader) {
            case GPT:
                return InstallerDaemon.PartitionTable.GPT;
            case MSDOS:
                return InstallerDaemon.PartitionTable.MSDOS;
            case NONE:
            default:
                return InstallerDaemon.PartitionTable.NONE;
        }
    }
}

private void on_bus_acquired (GLib.DBusConnection connection, string name) {
    try {
        connection.register_object ("/io/elementary/InstallerDaemon", new InstallerDaemon.Daemon ());
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
