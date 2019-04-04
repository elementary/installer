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

const double SECTORS_AS_GIB = 2 * 1024 * 1024;

namespace Utils {
    public string string_from_utf8 (uint8[] input) {
        var builder = new GLib.StringBuilder.sized (input.length);
        builder.append_len ((string) input, input.length);
        return (owned) builder.str;
    }

    public void decrypt_partition (Distinst.Disks disks, string device, string pv, string password) throws GLib.IOError {
        string error_msg;
        if (Distinst.device_map_exists (pv)) {
            error_msg = _("Device name already exists.");
        } else {
            int result = disks.decrypt_partition (device, Distinst.LvmEncryption () {
                physical_volume = pv,
                password = password,
                keydata = null
            });

            switch (result) {
                case 0:
                    return;
                case 1:
                    error_msg = _("An input was null.");
                    break;
                case 2:
                    error_msg = _("An input was not valid UTF-8.");
                    break;
                case 3:
                    error_msg = _("Either a password or keydata string must be supplied.");
                    break;
                case 4:
                    error_msg = _("Failed to decrypt due to invalid password.");
                    break;
                case 5:
                    error_msg = _("The decrypted partition does not have a LVM volume on it.");
                    break;
                case 6:
                    error_msg = _("Unable to locate LUKS partition at %s.").printf (device);
                    break;
                default:
                    error_msg = _("Fatal error occurred: check logs");
                    critical ("decrypt: unhandled error value: %d", result);
                    break;
            }
        }

        throw new GLib.IOError.FAILED (error_msg);
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
            Installer.App.get_instance ().quit ();
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
                system_instance = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
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
                seat_instance = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DisplayManager", Environment.get_variable ("XDG_SEAT_PATH"), DBusProxyFlags.NONE);
            } catch (GLib.Error e) {
                critical ("DisplayManager.Seat error: %s", e.message);
            }
        }

        return seat_instance;
    }

    string get_distribution_logo_from_alongside (Distinst.AlongsideOption option) {
    if (option.is_linux ()) {
        Distinst.OsRelease os_release;
        if (option.get_os_release (out os_release) == 0) {
            return get_distribution_logo (os_release);
        } else {
            return "tux";
        }
    } else if (option.is_mac_os ()) {
        return "drive-harddisk-solidstate";
    } else if (option.is_windows ()) {
        return "distributor-logo-windows";
    } else {
        return "drive-harddisk-solidstate";
    }
}

string get_distribution_logo (Distinst.OsRelease os_release) {
    switch (os_release.name) {
        case "Antergos":
            return "distributor-logo-antergos";
        case "Chakra":
            return "distributor-logo-chakra";
        case "elementary":
            return "distributor-logo-elementary";
        case "Korora":
            return "distributor-logo-korora";
        case "Kubuntu":
            return "distributor-logo-kubuntu";
        case "Linux Mint":
            return "distributor-logo-linux-mint";
        case "Lubuntu":
            return "distributor-logo-lubuntu";
        case "Mageia":
            return "distributor-logo-mageia";
        case "Manjaro":
            return "distributor-logo-manjaro";
        case "OpenSUSE":
            return "distributor-logo-opensuse";
        case "Pop!_OS":
            return "distributor-logo-popos";
        case "Ubuntu MATE":
            return "distributor-logo-ubuntu-mate";
        default:
            switch (os_release.id) {
                case "centos":
                    return "distributor-logo-centos";
                case "ubuntu":
                    return "distributor-logo-ubuntu";
                default:
                    switch (os_release.id_like) {
                        case "archlinux":
                            return "distributor-logo-archlinux";
                        case "debian":
                            return "distributor-logo-debian";
                        case "fedora":
                            return "distributor-logo-fedora";
                        case "gentoo":
                            return "distributor-logo-gentoo";
                        default:
                            return "tux";
                    }
            }
        }

        return "tux";
    }
}
