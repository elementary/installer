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

public struct InstallerDaemon.Partition {
    string device_path;

    Distinst.FileSystem filesystem;

    uint64 start_sector;
    uint64 end_sector;
    Distinst.PartitionUsage sectors_used;
    string? current_lvm_volume_group;
}

public struct InstallerDaemon.InstallConfig {
    string hostname;
    string keyboard_layout;
    string keyboard_variant;
    string lang;
    uint8 flags;
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
    Distinst.FileSystem filesystem;
    MountFlags flags;

    public bool is_valid_boot_mount () {
        return filesystem == Distinst.FileSystem.FAT16
            || filesystem == Distinst.FileSystem.FAT32;
    }

    public bool is_valid_root_mount () {
        return filesystem != Distinst.FileSystem.FAT16
            && filesystem != Distinst.FileSystem.FAT32
            && filesystem != Distinst.FileSystem.NTFS;
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
