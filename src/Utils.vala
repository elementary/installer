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

namespace Utils {
    private static async bool detect_system (GLib.File mount_point, out string name, out string? version, out GLib.Icon icon) {
        name = "";
        version = null;
        icon = null;
        var efi_identifier = mount_point.get_child ("EFI");
        if (efi_identifier.query_exists ()) {
            return false;
        }

        // Try to detect a Linux system
        var linux_identifier = mount_point.get_child ("etc").get_child ("os-release");
        if (linux_identifier.query_exists ()) {
            string _name = "Linux";
            try {
                FileInputStream @is = yield linux_identifier.read_async ();
                DataInputStream dis = new DataInputStream (@is);
                string line;

                while ((line = yield dis.read_line_async ()) != null) {
                    if (!("=" in line))
                        continue;

                    var parts = line.split ("=", 2);
                    if (parts[0] == "NAME") {
                        _name = parts[1].replace ("\"", "");
                    }

                    if (parts[0] == "VERSION") {
                        version = parts[1].replace ("\"", "");
                    }
                }
            } catch (Error e) {
                stdout.printf ("Error: %s\n", e.message);
            }

            name = _name;
            switch (_name) {
                case "elementary OS":
                    icon = new GLib.ThemedIcon ("os-linux-elementary");
                    break;
                case "Ubuntu":
                    icon = new GLib.ThemedIcon ("os-linux-ubuntu");
                    break;
                case "Arch Linux":
                    icon = new GLib.ThemedIcon ("os-linux-arch");
                    break;
                case "Fedora":
                    icon = new GLib.ThemedIcon ("os-linux-fedora");
                    break;
                case "Manjaro Linux":
                    icon = new GLib.ThemedIcon ("os-linux-manjaro");
                    break;
                case "Debian GNU/Linux":
                    icon = new GLib.ThemedIcon ("os-linux-debian");
                    break;
                case "openSUSE":
                    icon = new GLib.ThemedIcon ("os-linux-opensuse");
                    break;
                case "elementary":
                    icon = new GLib.ThemedIcon ("os-linux-elementary");
                    break;
                default:
                    GLib.File icon_file = mount_point.get_child (".VolumeIcon.png");
                    if (icon_file.query_exists ()) {
                        icon = new GLib.FileIcon (icon_file);
                    } else {
                        icon = new GLib.ThemedIcon ("os-linux");
                    }
                    break;
            }
            return true;
        }

        // Try to detect a Windows system
        var windows_identifier = mount_point.get_child ("Windows").get_child ("System32").get_child ("ntoskrnl.exe");
        if (windows_identifier.query_exists ()) {
            name = "Windows";
            icon = new GLib.ThemedIcon ("os-windows");
            return true;
        }

        // Try to detect a Mac OS system
        var macos_identifier = mount_point.get_child ("System").get_child ("Library").get_child ("CoreServices").get_child ("SystemVersion.plist");
        if (macos_identifier.query_exists ()) {
            string product_name = "macOS";
            string product_version = "10.10";
            unowned Xml.Doc* doc = Xml.Parser.read_file (macos_identifier.get_path ());
            Xml.Node* root = doc->get_root_element ();
            if (root == null) {
                delete doc;
            } else {
                for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
                    if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                        if (iter->name == "dict") {
                            bool was_product_name = false;
                            bool was_version = false;
                            for (Xml.Node* subiter = iter->children; subiter != null; subiter = subiter->next) {
                                if (subiter->name == "key" && subiter ->get_content () == "ProductName") {
                                    was_product_name = true;
                                } else if (subiter->name == "key" && subiter ->get_content () == "ProductUserVisibleVersion") {
                                    was_version = true;
                                } else if (was_product_name && subiter->name == "string") {
                                    was_product_name = false;
                                    product_name = subiter ->get_content ();
                                } else if (was_version && subiter->name == "string") {
                                    was_version = false;
                                    product_version = subiter ->get_content ();
                                }
                            }
                        }
                    }
                }
            }

            name = product_name;
            version = product_version;
            icon = new GLib.ThemedIcon ("os-unix-mac");
            return true;
        }

        // Try to detect a unknwon Linux system
        var linux_fallback_identifier = mount_point.get_child ("etc");
        if (linux_fallback_identifier.query_exists ()) {
            name = "Linux";
            icon = new GLib.ThemedIcon ("os-linux");
            return true;
        }

        return false;
    }

    private static string get_pretty_name () {
        string pretty_name = _("Operating System");
        const string ETC_OS_RELEASE = "/etc/os-release";

        try {
            var data_stream = new DataInputStream (File.new_for_path (ETC_OS_RELEASE).read ());

            string line;
            while ((line = data_stream.read_line (null)) != null) {
                var osrel_component = line.split ("=", 2);
                if (osrel_component.length == 2 && osrel_component[0] == "PRETTY_NAME") {
                    pretty_name = osrel_component[1].replace ("\"", "");
                    break;
                }
            }
        } catch (Error e) {
            warning ("Couldn't read os-release file: %s", e.message);
        }

        return pretty_name;
    }
}
