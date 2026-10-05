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
}

[DBus (name = "io.elementary.InstallerDaemon")]
public class InstallerDaemon.BackendProxy : GLib.Object {
    private InstallerDaemon.InstallerInterface backend_proxy = null;

    public signal void on_error (InstallerDaemon.Error error);
    public signal void on_status (InstallerDaemon.Status status);
    public signal void on_log_message (InstallerDaemon.LogLevel level, string message);

    private void check () throws GLib.Error {
        if (backend_proxy == null) {
            throw new GLib.IOError.FAILED ("Backend not set");
        }
    }

    public void set_backend (InstallerDaemon.Backend backend) throws GLib.Error {
        if (backend_proxy != null) {
            throw new GLib.IOError.FAILED ("Backend already set");
        }

        switch (backend) {
            case InstallerDaemon.Backend.DISTINST:
                backend_proxy = new InstallerDaemon.DistinstBackend ();
                break;
            case InstallerDaemon.Backend.REPART:
                backend_proxy = new InstallerDaemon.RepartBackend ();
                break;
            default:
                throw new GLib.IOError.FAILED ("Unknown backend");
        }

        backend_proxy.on_error.connect ((error) => on_error (error));
        backend_proxy.on_status.connect ((status) => on_status (status));
        backend_proxy.on_log_message.connect ((level, message) => on_log_message (level, message));
    }

    public InstallerDaemon.PartitionTable bootloader_detect () throws GLib.Error {
        check ();
        return backend_proxy.bootloader_detect ();
    }

    public InstallerDaemon.DiskInfo get_disks (bool get_partitions = false) throws GLib.Error {
        check ();
        return backend_proxy.get_disks (get_partitions);
    }

    public int decrypt_partition (string path, string pv, string password) throws GLib.Error {
        check ();
        return backend_proxy.decrypt_partition (path, pv, password);
    }

    public InstallerDaemon.Disk get_logical_device (string pv) throws GLib.Error {
        check ();
        return backend_proxy.get_logical_device (pv);
    }

    public void install_with_default_disk_layout (InstallerDaemon.InstallConfig config, string disk, bool encrypt, string encryption_password) throws GLib.Error {
        check ();
        backend_proxy.install_with_default_disk_layout (config, disk, encrypt, encryption_password);
    }

    public void install_with_custom_disk_layout (InstallerDaemon.InstallConfig config, InstallerDaemon.Mount[] disk_config, InstallerDaemon.LuksCredentials[] luks) throws GLib.Error {
        check ();
        backend_proxy.install_with_custom_disk_layout (config, disk_config, luks);
    }
}

private static GLib.MainLoop loop;

private void on_bus_acquired (GLib.DBusConnection connection, string name) {
    try {
        connection.register_object ("/io/elementary/InstallerDaemon", new InstallerDaemon.BackendProxy ());
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
