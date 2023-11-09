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

public struct InstallerDaemon.DiskInfo {
    Disk[] physical_disks;
    Disk[] logical_disks;
}

public struct InstallerDaemon.Disk {
    string name;
    string device_path;
    uint64 sectors;
    uint64 sector_size;
    bool rotational;
    bool removable;

    Partition[] partitions;
}

public enum InstallerDaemon.FileSystem {
    NONE,
    BTRFS,
    EXT2,
    EXT3,
    EXT4,
    F2FS,
    FAT16,
    FAT32,
    NTFS,
    SWAP,
    XFS,
    LVM,
    LUKS;

    public string to_string () {
        switch (this) {
            case BTRFS:
                return "btrfs";
            case EXT2:
                return "ext2";
            case EXT3:
                return "ext3";
            case EXT4:
                return "ext4";
            case F2FS:
                return "f2fs";
            case FAT16:
                return "fat16";
            case FAT32:
                return "fat32";
            case NONE:
                return "none";
            case NTFS:
                return "ntfs";
            case SWAP:
                return "swap";
            case XFS:
                return "xfs";
            case LVM:
                return "lvm";
            case LUKS:
                return "luks";
        }

        return "none";
    }
}

public struct InstallerDaemon.PartitionUsage {
    /**
     * None = 0; Some(usage) = 1;
     */
    public uint8 tag;
    /**
     * The size, in sectors, that a partition is used.
     */
    public uint64 value;
}

public enum InstallerDaemon.PartitionTable {
    NONE,
    GPT,
    MSDOS;
}

public enum InstallerDaemon.Step {
    BACKUP,
    INIT,
    PARTITION,
    EXTRACT,
    CONFIGURE,
    BOOTLOADER;
}

public struct InstallerDaemon.Status {
    Step step;
    int percent;
}

public struct InstallerDaemon.Partition {
    string device_path;

    FileSystem filesystem;

    uint64 start_sector;
    uint64 end_sector;
    PartitionUsage sectors_used;
    string? current_lvm_volume_group;
}

public struct InstallerDaemon.InstallConfig {
    string hostname;
    string keyboard_layout;
    string keyboard_variant;
    string lang;
    bool modify_boot_order;
    bool install_drivers;
}

[Flags]
public enum InstallerDaemon.MountFlags {
    FORMAT = 1,
    LVM = 2,
    LVM_ON_LUKS = 4
}

public struct InstallerDaemon.Mount {
    string partition_path;
    string parent_disk;
    string mount_point;
    uint64 sectors;
    FileSystem filesystem;
    MountFlags flags;

    public bool is_valid_boot_mount () {
        return filesystem == FileSystem.FAT16
            || filesystem == FileSystem.FAT32;
    }

    public bool is_valid_root_mount () {
        return filesystem != FileSystem.FAT16
            && filesystem != FileSystem.FAT32
            && filesystem != FileSystem.NTFS;
    }

    public bool is_lvm () {
        return MountFlags.LVM in flags;
    }

    public bool should_format () {
        return MountFlags.FORMAT in flags;
    }
}

public struct InstallerDaemon.LuksCredentials {
    string device;
    string pv;
    string password;
}
