// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016 elementary LLC. (https://elementary.io)
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

public class Recovery : GLib.Object {
    private static Recovery _recovery;
    public static unowned Recovery get_default () {
        if (_recovery == null) {
            try {
                _recovery = Recovery.load ("/cdrom/recovery.conf");
            } catch (Error e) {
                warning ("Couldn't read recovery.conf file: %s", e.message);
                _recovery = new Recovery ();
            }
        }

        return _recovery;
    }

    public static string? efi_partition () {
        unowned Recovery recovery = Recovery.get_default ();

        if (recovery.efi_uuid != null) {
            return Posix.realpath ("/dev/disk/by-uuid/" + recovery.efi_uuid);
        } else {
            return null;
        }
    }

    public static string? recovery_partition () {
        unowned Recovery recovery = Recovery.get_default ();

        if (recovery.recovery_uuid != null) {
            return Posix.realpath ("/dev/disk/by-uuid/" + recovery.recovery_uuid);
        } else {
            return null;
        }
    }

    public static string? root_partition () {
        unowned Recovery recovery = Recovery.get_default ();

        if (recovery.root_uuid != null) {
            return Posix.realpath ("/dev/disk/by-uuid/" + recovery.root_uuid);
        } else {
            return null;
        }
    }

    public static string? disk () {
        var recovery_dev = Recovery.recovery_partition ();

        if (recovery_dev != null) {
            try {
                var recovery_name = Path.get_basename (recovery_dev);
                var recovery_sys = Posix.realpath ("/sys/class/block/" + recovery_name);

                var disk_sys = Path.get_dirname (recovery_sys);
                var disk_name = Path.get_basename (disk_sys);
                var disk_dev = "/dev/" + disk_name;

                return disk_dev;
            } catch (GLib.Error e) {
                critical ("failed to find disk device for recovery automatically: %s", e.message);
            }
        }

        return null;
    }

    public static string? lvm_partition () {
        string root_dev = Recovery.root_partition ();

        if (root_dev != null) {
            string root_name = Path.get_basename (root_dev);

            var slave_name = resolve_slave(root_name);
            if (slave_name != null) {
                var slave_dev = "/dev/" + slave_name;
                return slave_dev;
            }
        }

        return null;
    }

    private static string? resolve_slave(string name) {
        stdout.printf("resolve_slave(%s)\n", name);

        try {
            var slaves_path = "/sys/class/block/" + name + "/slaves/";
            var slaves_dir = File.new_for_path (slaves_path);
            if (!slaves_dir.query_exists ()) {
                return name;
            }

            var slaves_iter = slaves_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            var slaves = new Gee.ArrayList<string> ();
            FileInfo info;
            while ((info = slaves_iter.next_file ()) != null) {
                slaves.add (info.get_name ());
            }

            if (slaves.size == 1) {
                return resolve_slave(slaves[0]);
            } else {
                critical ("failed to find slave device of %s automatically: incorrect number of LVM slaves: %d", name, slaves.size);
            }
        } catch (GLib.Error e) {
            critical ("failed to find slave device of %s automatically: %s", name, e.message);
        }

        return null;
    }

    private static Recovery? load (string path) throws GLib.Error {
        var recovery = new Recovery();

        var data_stream = new DataInputStream (File.new_for_path (path).read ());

        string line;
        while ((line = data_stream.read_line (null)) != null) {
            var parts = line.split ("=", 2);

            string name = parts[0];
            string? val = null;
            if (parts.length >= 2) {
                val = parts[1];
            }

            if (name == "LANG") {
                if (val != null) {
                    var lang_parts = val.split ("_", 2);
                    recovery.lang = lang_parts[0];
                    if (lang_parts.length >= 2) {
                        var country_parts = lang_parts[1].split(".", 2);
                        recovery.country = country_parts[0];
                    }
                } else {
                    recovery.lang = null;
                    recovery.country = null;
                }
            } else if (name == "KBD_LAYOUT") {
                recovery.keyboard_layout = val;
            } else if (name == "KBD_MODEL") {
                recovery.keyboard_model = val;
            } else if (name == "KBD_VARIANT") {
                recovery.keyboard_variant = val;
            } else if (name == "EFI_UUID") {
                recovery.efi_uuid = val;
            } else if (name == "RECOVERY_UUID") {
                recovery.recovery_uuid = val;
            } else if (name == "ROOT_UUID") {
                recovery.root_uuid = val;
            }
        }

        return recovery;
    }

    public string? lang { get; set; default = null; }
    public string? country { get; set; default = null; }
    public string? keyboard_layout { get; set; default = null; }
    public string? keyboard_model { get; set; default = null; }
    public string? keyboard_variant { get; set; default = null; }
    public string? encryption_password { get; set; default = null; }
    public string? efi_uuid { get; set; default = null; }
    public string? recovery_uuid { get; set; default = null; }
    public string? root_uuid { get; set; default = null; }
    public Gee.ArrayList<Installer.Mount>? mounts { get; set; default = null; }
    public Gee.ArrayList<Installer.LuksCredentials>? luks { get; set; default = null; }
}
