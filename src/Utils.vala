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
        if (Installer.App.test_mode || Installer.App.load_view != null) {
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
        if (Installer.App.test_mode || Installer.App.load_view != null) {
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
        if (Installer.App.test_mode || Installer.App.load_view != null) {
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
}
