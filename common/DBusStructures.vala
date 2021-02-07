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
    public string partition_path;
    public string parent_disk;
    public string mount_point;
    public uint64 sectors;
    public Distinst.FileSystem filesystem;
    public MountFlags flags;

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
    public string device;
    public string pv;
    public string password;
}
