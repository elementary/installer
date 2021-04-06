// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright 2016–2021 elementary, Inc. (https://elementary.io)
 * Copyright 2006-2021 ubiquity Developers (https://launchpad.net/ubiquity)
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
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 *              Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

namespace Utils {
    private static string? pretty_name;
    private static string get_pretty_name () {
        if (pretty_name == null) {
            pretty_name = GLib.Environment.get_os_info (GLib.OsInfoKey.PRETTY_NAME);
        }

        return pretty_name;
    }

    public static void shutdown () {
        if (Installer.App.test_mode) {
            critical (_("Test mode shutdown"));
        } else {
            get_system_instance ();

            try {
                system_instance.power_off (false);
            } catch (GLib.Error e) {
                critical (e.message);
            }
        }
    }

    private static void restart () {
        if (Installer.App.test_mode) {
            critical (_("Test mode reboot"));
        } else {
            get_system_instance ();

            try {
                system_instance.reboot (false);
            } catch (GLib.Error e) {
                critical (e.message);
            }
        }
    }

    private static void logout () {
        var session = Utils.get_session_instance ();
        if (session != null) {
            try {
                // Logout mode 2 is forcefully logout. No confirmation will be shown and any inhibitors will be ignored.
                session.logout (2);
            } catch (GLib.Error e) {
                warning ("DisplayManager.Seat error: %s", e.message);
            }
        }
    }

    private static void demo_mode () {
        if (Installer.App.test_mode) {
            critical (_("Test mode switch user"));
        } else {
            // This touches the file `/var/lib/lightdm/demo-mode`, which signals to the greeter that the next session it launches
            // should be the live (demo) session. If this file doesn't exist, it just relaunches the installer session
            Installer.Daemon.get_default ().trigger_demo_mode.begin ((obj, res) => {
                try {
                    ((Installer.Daemon)obj).trigger_demo_mode.end (res);
                    logout ();
                } catch (Error e) {
                    warning ("Error triggering demo mode: %s", e.message);
                }
            });
        }
    }

    [DBus (name = "org.freedesktop.login1.Manager")]
    interface SystemInterface : Object {
        public abstract void reboot (bool interactive) throws GLib.Error;
        public abstract void power_off (bool interactive) throws GLib.Error;
    }

    private static SystemInterface? system_instance;
    private static void get_system_instance () {
        if (system_instance == null) {
            try {
                system_instance = Bus.get_proxy_sync (
                    BusType.SYSTEM,
                    "org.freedesktop.login1",
                    "/org/freedesktop/login1"
                );
            } catch (GLib.Error e) {
                warning ("%s", e.message);
            }
        }
    }

    [DBus (name = "org.gnome.SessionManager")]
    interface SessionInterface : Object {
        public abstract void logout (uint type) throws GLib.Error;
    }

    private static SessionInterface? session_instance;
    private static unowned SessionInterface? get_session_instance () {
        if (session_instance == null) {
            try {
                session_instance = Bus.get_proxy_sync (
                    BusType.SESSION,
                    "org.gnome.SessionManager",
                    "/org/gnome/SessionManager",
                    DBusProxyFlags.NONE
                );
            } catch (GLib.Error e) {
                critical ("SessionManager error: %s", e.message);
            }
        }

        return session_instance;
    }

    [DBus (name = "org.freedesktop.hostname1")]
    interface HostnameInterface : Object {
        public abstract string chassis { owned get; }
    }

    private static HostnameInterface? hostname_interface_instance;
    private static void get_hostname_interface_instance () {
        if (hostname_interface_instance == null) {
            try {
                hostname_interface_instance = Bus.get_proxy_sync (
                    BusType.SYSTEM,
                    "org.freedesktop.hostname1",
                    "/org/freedesktop/hostname1"
                );
            } catch (GLib.Error e) {
                warning ("%s", e.message);
            }
        }
    }

    private string get_chassis () {
        get_hostname_interface_instance ();

        return hostname_interface_instance.chassis;
    }

    private string? get_machine_id () {
        string machine_id;
        try {
            FileUtils.get_contents ("/etc/machine-id", out machine_id);
        } catch (FileError e) {
            warning ("%s", e.message);
            return null;
        }

        return machine_id.strip ();
    }

    private static string? get_sys_vendor () {
        string vendor;
        try {
            FileUtils.get_contents ("/sys/devices/virtual/dmi/id/sys_vendor", out vendor);
        } catch (FileError e) {
            warning ("%s", e.message);
            return null;
        }

        return vendor.strip ();
    }

    private static string? get_product_name () {
        string model;
        try {
            FileUtils.get_contents ("/sys/devices/virtual/dmi/id/product_name", out model);
        } catch (FileError e) {
            warning ("%s", e.message);
            return null;
        }

        return model.strip ();
    }

    private static string? get_product_version () {
        string model;
        try {
            FileUtils.get_contents ("/sys/devices/virtual/dmi/id/product_version", out model);
        } catch (FileError e) {
            warning ("%s", e.message);
            return null;
        }

        return model.strip ();
    }

    // Based on https://git.launchpad.net/ubiquity/tree/ubiquity/misc.py?id=ae6415d224c2e76afa2274cc9f85997f38870419#n648
    private static string? get_ubiquity_compatible_hostname () {
        string model = get_product_name ();
        string manufacturer = get_sys_vendor ();

        if (manufacturer.length == 0) {
            return null;
        }
        manufacturer = manufacturer.down ();

        if (manufacturer.contains ("to be filled")) {
            // Don't bother with products in development.
            return null;
        }

        if (manufacturer.contains ("bochs") || manufacturer.contains ("vmware")) {
            model = "virtual machine";
            // VirtualBox sets an appropriate system-product-name.
        } else {
            if (manufacturer.contains ("lenovo") || manufacturer.contains ("ibm")) {
                model = get_product_version ();
            }
        }

        try {
            if (manufacturer.contains ("apple")) {
                //  MacBook4,1 - strip the 4,1
                var re = new Regex ("[^a-zA-Z\\s]");
                model = re.replace (model, model.length, 0, "");
            }

            // Replace each gap of non-alphanumeric characters with a dash.
            // Ensure the resulting string does not begin or end with a dash.
            var re = new Regex ("[^a-zA-Z0-9]+");
            model = re.replace (model, model.length, 0, "-");
            while (model[0] == '-') {
                model = model.substring (1);
            }
            while (model[model.length - 1] == '-') {
                model = model.substring (0, model.length - 1);
            }

            if (model.down () == "not-available") {
                return null;
            }
            if (model.down () == "To be filled by O.E.M.".down ()) {
                return null;
            }
        } catch (RegexError e) {
            warning ("Error cleaning up hostname strings: %s", e.message);
            return null;
        }

        return model;
    }

    public static string get_hostname () {
        string hostname = get_ubiquity_compatible_hostname () ?? ("elementary-os" + "-" + get_chassis ());
        hostname += "-" + get_machine_id ().substring (0, 8);

        return hostname;
    }

    public static string[] get_kernel_parameters () {
        string cmdline;

        try {
            FileUtils.get_contents ("/proc/cmdline", out cmdline);
        } catch (Error e) {
            warning ("Could not read kernel parameters: %s", e.message);
        }

        return cmdline.split (" ");
    }
}
