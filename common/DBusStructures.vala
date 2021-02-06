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

public struct InstallerDaemon.PartitionConfig {
    string placeholder;
}
