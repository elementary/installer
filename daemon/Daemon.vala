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

[DBus (name = "io.elementary.InstallerDaemon")]
protected interface InstallerDaemon.InstallerInterface : GLib.Object {
    public signal void on_error (InstallerDaemon.Error error);
    public signal void on_status (InstallerDaemon.Status status);
    public signal void on_log_message (InstallerDaemon.LogLevel level, string message);

    public abstract InstallerDaemon.PartitionTable bootloader_detect () throws GLib.Error;

    public abstract InstallerDaemon.DiskInfo get_disks (bool get_partitions = false) throws GLib.Error;
    public abstract int decrypt_partition (string path, string pv, string password) throws GLib.Error;
    public abstract InstallerDaemon.Disk get_logical_device (string pv) throws GLib.Error;
    public abstract void install_with_default_disk_layout (InstallerDaemon.InstallConfig config, string disk, bool encrypt, string encryption_password) throws GLib.Error;
    public abstract void install_with_custom_disk_layout (InstallerDaemon.InstallConfig config, InstallerDaemon.Mount[] disk_config, InstallerDaemon.LuksCredentials[] luks) throws GLib.Error;
    public abstract void set_demo_mode_locale (string locale) throws GLib.Error;
    public abstract void trigger_demo_mode () throws GLib.Error;
}

private static GLib.MainLoop loop;

private void on_bus_acquired (GLib.DBusConnection connection, string name) {
    try {
        connection.register_object ("/io/elementary/InstallerDaemon", get_backend ());
    } catch (GLib.Error e) {
        critical ("Unable to register the object: %s", e.message);
    }
}

public static InstallerDaemon.InstallerInterface get_backend () {
    return new InstallerDaemon.RepartBackend ();
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
