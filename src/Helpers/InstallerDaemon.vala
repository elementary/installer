public class Installer.Daemon {
    [DBus (name = "io.elementary.InstallerDaemon")]
    private interface InstallerInterface : GLib.DBusProxy {
        public async abstract InstallerDaemon.DiskInfo get_disks (bool get_partitions = false) throws GLib.Error;
        public async abstract int decrypt_partition (string path, string pv, string password) throws GLib.Error;
        public async abstract InstallerDaemon.Disk get_logical_device (string pv) throws GLib.Error;
    }

    private InstallerInterface daemon;

    private Daemon () {
        daemon = Bus.get_proxy_sync (BusType.SYSTEM, "io.elementary.InstallerDaemon", "/io/elementary/InstallerDaemon");
    }

    public async InstallerDaemon.DiskInfo get_disks (bool get_partitions = false) throws GLib.Error {
        return yield daemon.get_disks (get_partitions);
    }

    public async int decrypt_partition (string path, string pv, string password) throws GLib.Error {
        return yield daemon.decrypt_partition (path, pv, password);
    }

    public async InstallerDaemon.Disk get_logical_device (string pv) throws GLib.Error {
        return yield daemon.get_logical_device (pv);
    }

    private static Daemon? _instance = null;
    public static unowned Daemon get_default () {
        if (_instance != null) {
            return _instance;
        }

        _instance = new Daemon ();
        return _instance;
    }
}
