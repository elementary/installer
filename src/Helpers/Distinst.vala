// Copyright 2021 System76
// SPDX-License-Identifier: GPL-3.0-or-later

public struct Device {
    public string path;
}

public struct EncryptedDevice {
    public Device device;
    public string uuid;
}

public struct OsEntry {
    /** Pop!_OS */
    public string name;

    /** FS UUID */
    public string uuid;
}

public struct OsInfo {
    /** Which device it resides upon */
    public Device device;

    /** Linux, Windows, etc. */
    public string identifier;

    /** Pop!_OS, Ubuntu */
    public string name;

    /** 20.04 */
    public string version;
}

[DBus(name = "com.system76.Distinst")]
public interface DistinstIface: Object {
    /** Fetch a list of encrypted block devices that we can decrypt. */
    public abstract void encrypted_devices() throws Error;

    /** Encountered error when locating encrypted devices. */
    public signal void encrypted_devices_err(string why);

    /** Successfully located encrypted devices. */
    public signal void encrypted_devices_ok(EncryptedDevice[] devices);

    /** Initiate disk rescan. */
    public abstract void disk_rescan() throws Error;

    /** Disk rescan complete. */
    public signal void disk_rescan_complete();

    /** Checks if the environment is in OEM mode. */
    public abstract bool is_oem_mode() throws Error;

    /** Search for installed operating systems by their boot entries. */
    public abstract void os_entries() throws Error;

    /** Signals that searching for OS entries failed */
    public signal void os_entries_err(string why);

    /** Signals that OS boot entries were discovered. */
    public signal void os_entries_ok(OsEntry[] entries);

    /** Search for installed operating systems on accessible file systems. */
    public abstract void os_search() throws Error;

    /** Signals that an OS search failed. */
    public signal void os_search_err(string why);

    /** Signals that an OS search successfully found operating systems. */
    public signal void os_search_ok(OsInfo[] info);

    /** Begin the process of decrypting a block device. */
    public abstract void decrypt(string uuid, string key) throws Error;

    /** Signals that a decryption attempt failed. */
    public signal void decrypt_err(string why);

    /** Signals that a decryption attempt was successful. */
    public signal void decrypt_ok();
}