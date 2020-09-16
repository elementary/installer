// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016–2018 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 *              Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

namespace Utils {
    public string string_from_utf8 (uint8[] input) {
        var builder = new GLib.StringBuilder.sized (input.length);
        builder.append_len ((string) input, input.length);
        return (owned) builder.str;
    }

    private struct OsRelease {
        public string pretty_name;

        public static OsRelease new () {
            return OsRelease () {
                pretty_name = string_from_utf8 (Distinst.get_os_pretty_name ())
            };
        }
    }

    private static OsRelease? os_release;

    private static string get_pretty_name () {
        if (os_release == null) {
            os_release = OsRelease.new ();
        }

        return os_release.pretty_name;
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

    private static void demo_mode () {
        if (Installer.App.test_mode) {
            critical (_("Test mode switch user"));
        } else {
            get_system_instance ();

            var seat = Utils.get_seat_instance ();
            if (seat != null) {
                try {
                    seat.switch_to_guest ("");
                } catch (GLib.Error e) {
                    stderr.printf ("DisplayManager.Seat error: %s\n", e.message);
                }
            }
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

    [DBus (name = "org.freedesktop.DisplayManager.Seat")]
    public interface SeatInterface : Object {
        public abstract bool has_guest_account { get; }
        public abstract void switch_to_guest (string session_name) throws GLib.Error;
    }

    private static SeatInterface? seat_instance;
    public static unowned SeatInterface? get_seat_instance () {
        if (seat_instance == null) {
            try {
                seat_instance = Bus.get_proxy_sync (
                    BusType.SYSTEM,
                    "org.freedesktop.DisplayManager",
                    Environment.get_variable ("XDG_SEAT_PATH"),
                    DBusProxyFlags.NONE
                );
            } catch (GLib.Error e) {
                critical ("DisplayManager.Seat error: %s", e.message);
            }
        }

        return seat_instance;
    }

    // Based on https://git.launchpad.net/ubiquity/tree/ubiquity/misc.py#n648
    public static string? get_hostname () {
        string model = "";

        try {
            string[] process_args = {"dmidecode", "--quiet", "--string", "system-manufacturer"};
            string[] process_env = Environ.get ();
            string process_stdout;
            string process_stderr;
            int process_status;

            Process.spawn_sync (null,
                                process_args,
                                process_env,
                                SpawnFlags.SEARCH_PATH,
                                null,
                                out process_stdout,
                                out process_stderr,
                                out process_status);

            string manufacturer = process_stdout;
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
                string key = "system-product-name";
                if (manufacturer.contains ("lenovo") || manufacturer.contains ("ibm")) {
                    key = "system-version";
                }

                Process.spawn_sync (null,
                    {"dmidecode", "--quiet", "--string", key},
                    process_env,
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out process_stdout,
                    out process_stderr,
                    out process_status);

                model = process_stdout;
            }

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
        } catch (SpawnError e) {
            print ("Error: %s\n", e.message);
        } catch (RegexError e) {
            print ("Error: %s\n", e.message);
        }

        return model;
    }
}
