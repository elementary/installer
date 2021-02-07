public class Installer.Daemon {
    // Wait up to 60 seconds for DBus calls to timeout. Some of the Distinst disk probe operations seem to take around 30 seconds
    private const int DBUS_TIMEOUT_MSEC = 60 * 1000;

    [DBus (name = "io.elementary.InstallerDaemon")]
    private interface InstallerInterface : GLib.DBusProxy {
        public signal void on_error (Distinst.Error error);
        public signal void on_status (Distinst.Status status);
        public signal void on_log_message (Distinst.LogLevel level, string message);

        public abstract Distinst.PartitionTable bootloader_detect () throws GLib.Error;

        public async abstract InstallerDaemon.DiskInfo get_disks (bool get_partitions = false) throws GLib.Error;
        public async abstract int decrypt_partition (string path, string pv, string password) throws GLib.Error;
        public async abstract InstallerDaemon.Disk get_logical_device (string pv) throws GLib.Error;
        public async abstract void install_with_default_disk_layout (InstallerDaemon.InstallConfig config, string disk, bool encrypt, string encryption_password) throws GLib.Error;
        public async abstract void install_with_custom_disk_layout (InstallerDaemon.InstallConfig config, InstallerDaemon.Mount[] disk_config, InstallerDaemon.LuksCredentials[] luks) throws GLib.Error;
    }

    public signal void on_error (Distinst.Error error);
    public signal void on_status (Distinst.Status status);
    public signal void on_log_message (Distinst.LogLevel level, string message);

    private InstallerInterface daemon;

    private Daemon () {
        daemon = Bus.get_proxy_sync (BusType.SYSTEM, "io.elementary.InstallerDaemon", "/io/elementary/InstallerDaemon");
        daemon.g_default_timeout = DBUS_TIMEOUT_MSEC;

        daemon.on_error.connect ((error) => on_error (error));
        daemon.on_status.connect ((status) => on_status (status));
        daemon.on_log_message.connect ((level, message) => on_log_message (level, message));
    }

    public Distinst.PartitionTable bootloader_detect () throws GLib.Error {
        return daemon.bootloader_detect ();
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

    public async void install_with_default_disk_layout (InstallerDaemon.InstallConfig config, string disk, bool encrypt, string encryption_password) throws GLib.Error {
        yield daemon.install_with_default_disk_layout (config, disk, encrypt, encryption_password);
    }

    public async void install_with_custom_disk_layout (InstallerDaemon.InstallConfig config, InstallerDaemon.Mount[] disk_config, InstallerDaemon.LuksCredentials[] luks) throws GLib.Error {
        yield daemon.install_with_custom_disk_layout (config, disk_config, luks);
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
