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

public class Installer.DiskGrid : Gtk.Grid {
    public UDisks2.Drive drive;
    private Gee.LinkedList<UDisks2.Block> blocks;
    public DiskGrid (UDisks2.Drive drive) {
        this.drive = drive;
        show_all ();
    }

    construct {
        margin = 12;
        column_spacing = 6;
        orientation = Gtk.Orientation.HORIZONTAL;
        halign = Gtk.Align.CENTER;
        blocks = new Gee.LinkedList<UDisks2.Block> ();
    }

    public async void add_blocks (Gee.LinkedList<UDisks2.Block> received_blocks) {
        foreach (var block in received_blocks) {
            if (block.drive == ((DBusProxy) drive).g_object_path) {
                blocks.add (block);
                try {
                    UDisks2.Filesystem filesystem = yield Bus.get_proxy (BusType.SYSTEM, "org.freedesktop.UDisks2", ((DBusProxy) block).g_object_path);
                    process_filesystem (filesystem);
                } catch (Error e) {
                    warning (e.message);
                }
            }
        }

        received_blocks.remove_all (blocks);
    }

    private void process_filesystem (UDisks2.Filesystem filesystem) {
        bool software_mounted = false;
        string mount_point;
        if (filesystem.mount_points == null) {
            var mount_options = new GLib.HashTable<string, GLib.Variant> (str_hash, str_equal);
            mount_options.set ("options", new GLib.Variant.string ("ro"));
            try {
                mount_point = filesystem.mount (mount_options);
                software_mounted = true;
            } catch (Error e) {
                critical (e.message);
                return;
            }
        } else {
            var builder = new StringBuilder ();
            foreach (var character in filesystem.mount_points) {
                builder.append_unichar (character);
            }

            mount_point = builder.str;
        }

        var file = GLib.File.new_for_path (mount_point);
        var togglebutton = detect_system (file, filesystem);
        if (togglebutton != null) {
            add (togglebutton);
        }

        if (software_mounted) {
            var unmount_options = new GLib.HashTable<string, GLib.Variant> (str_hash, str_equal);
            try {
                filesystem.unmount (unmount_options);
            } catch (Error e) {
                critical (e.message);
            }
        }
    }

    private static ToggleOSButton? detect_system (GLib.File mount_point, UDisks2.Filesystem filesystem) {
        // Try to detect a Windows system
        var windows_identifier = mount_point.get_child ("Windows").get_child ("System32").get_child ("ntoskrnl.exe");
        if (windows_identifier.query_exists ()) {
            return new ToggleOSButton ("Windows", null, new GLib.ThemedIcon ("os-windows"), filesystem);
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

            return new ToggleOSButton (product_name, product_version, new GLib.ThemedIcon ("os-unix-mac"), filesystem);
        }

        // Try to detect a Linux system
        var linux_identifier = mount_point.get_child ("etc").get_child ("os-release");
        string name = "Linux";
        string? version = null;
        if (linux_identifier.query_exists ()) {
            try {
                FileInputStream @is = linux_identifier.read ();
                DataInputStream dis = new DataInputStream (@is);
                string line;

                while ((line = dis.read_line ()) != null) {
                    if (!("=" in line))
                        continue;

                    var parts = line.split ("=", 2);
                    if (parts[0] == "NAME") {
                        name = parts[1].replace ("\"", "");
                    }

                    if (parts[0] == "VERSION") {
                        version = parts[1].replace ("\"", "");
                    }
                }
            } catch (Error e) {
                stdout.printf ("Error: %s\n", e.message);
            }

            GLib.Icon icon;
            switch (name) {
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
                /* They are shipping an Ubuntu codename for now…
                case "Linux Mint":
                    icon = new GLib.ThemedIcon ("os-linux-mint");
                    break;*/
                case "openSUSE":
                    icon = new GLib.ThemedIcon ("os-linux-opensuse");
                    break;
                case "elementary":
                    icon = new GLib.ThemedIcon ("os-linux-elementary");
                    break;
                default:
                    icon = new GLib.ThemedIcon ("os-linux");
                    break;
            }
            return new ToggleOSButton (name, version, icon, filesystem);
        }

        return null;
    }

    public class ToggleOSButton : Gtk.ToggleButton {
        UDisks2.Filesystem filesystem;
        UDisks2.Partition partition;
        Gtk.Label description;
        Gtk.Label size;
        Gtk.Image icon_image;
        Gtk.Grid grid;
        public ToggleOSButton (string name, string? version, GLib.Icon icon, UDisks2.Filesystem filesystem) {
            this.filesystem = filesystem;
            if (version != null) {
                description.label = "%s %s".printf (name, version);
            } else {
                description.label = name;
            }

            try {
                partition = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.UDisks2", ((DBusProxy) filesystem).g_object_path);
                size.label = "(%s)".printf (GLib.format_size (partition.size));
            } catch (Error e) {
                warning (e.message);
            }

            icon_image.gicon = icon;
            show_all ();
        }
        
        construct {
            get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.column_spacing = 6;
            grid.row_spacing = 12;
            description = new Gtk.Label (null);
            description.xalign = 1;
            size = new Gtk.Label (null);
            size.xalign = 0;
            size.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            icon_image = new Gtk.Image ();
            icon_image.halign = Gtk.Align.CENTER;
            icon_image.icon_size = Gtk.IconSize.DIALOG;
            grid.attach (icon_image, 0, 0, 2, 1);
            grid.attach (description, 0, 1, 1, 1);
            grid.attach (size, 1, 1, 1, 1);
            add (grid);
        }
    }
}
