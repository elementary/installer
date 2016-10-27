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

public class Installer.DiskView : Gtk.Grid {
    Gtk.Stack load_stack;
    Gtk.Stack disk_stack;
    Gtk.ComboBoxText disk_combo;
    Gee.LinkedList<DiskGrid> disk_grids;
    Gtk.Grid choice_grid;

    public DiskView () {
        
    }

    construct {
        load_stack = new Gtk.Stack ();
        load_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        var load_grid = new Gtk.Grid ();
        load_grid.row_spacing = 12;
        load_grid.expand = true;
        load_grid.orientation = Gtk.Orientation.VERTICAL;
        load_grid.valign = Gtk.Align.CENTER;
        load_grid.halign = Gtk.Align.CENTER;
        var load_spinner = new Gtk.Spinner ();
        load_spinner.width_request = 48;
        load_spinner.height_request = 48;
        load_spinner.start ();
        var load_label = new Gtk.Label (_("Getting the current configuration…"));
        load_label.get_style_context ().add_class ("h2");
        load_grid.add (load_spinner);
        load_grid.add (load_label);
        load_stack.add_named (load_grid, "loading");

        disk_stack = new Gtk.Stack ();
        disk_stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;

        disk_combo = new Gtk.ComboBoxText ();
        disk_combo.changed.connect (() => {
            disk_stack.set_visible_child_name (disk_combo.active_id);
        });

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/pantheon/installer/icons/os");

        disk_grids = new Gee.LinkedList<DiskGrid> ();

        choice_grid = new Gtk.Grid ();
        choice_grid.orientation = Gtk.Orientation.VERTICAL;
        var group = new SList<Gtk.RadioButton> ();
        var clean_choice = new ChoiceItem (_("Clean Install"), _("Erase everything on your device and install a fresh copy of elementary OS."), new ThemedIcon ("ubiquity"), null);
        var upgrade_choice = new ChoiceItem (_("Upgrade"), _("An older version of elementary OS was detected on your system. Upgrade without losing any of your data or settings."), new ThemedIcon ("system-software-update"), clean_choice);
        choice_grid.add (clean_choice);
        choice_grid.add (upgrade_choice);

        add (load_stack);
        show_all ();
    }

    // If possible, open devices in a different thread so that the interface stays awake.
    public async void load () {
        var blocks = new Gee.LinkedList<UDisks2.Block> ();
        try {
            var client = yield DBusObjectManagerClient.new_for_bus (BusType.SYSTEM, GLib.DBusObjectManagerClientFlags.NONE,
                                                            "org.freedesktop.UDisks2", "/org/freedesktop/UDisks2", null);
            client.get_objects ().foreach ((object) => {
                var drive_interface = object.get_interface ("org.freedesktop.UDisks2.Drive");
                if (drive_interface != null) {
                    try {
                        UDisks2.Drive drive = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.UDisks2", object.get_object_path ());
                        if (drive.removable) {
                            return;
                        }

                        var grid = new DiskGrid (drive);
                        disk_grids.add (grid);
                    } catch (Error e) {
                        warning (e.message);
                    }
                } else {
                    var block_interface = object.get_interface ("org.freedesktop.UDisks2.Block");
                    if (block_interface != null) {
                        try {
                            UDisks2.Block block = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.UDisks2", object.get_object_path ());
                            // Make sure that it is a filesystem and not a partition table.
                            var filesystem_interface = object.get_interface ("org.freedesktop.UDisks2.Filesystem");
                            if (filesystem_interface != null) {
                                blocks.add (block);
                            }
                        } catch (Error e) {
                            warning (e.message);
                        }
                    }
                }
            });

            foreach (var grid in disk_grids) {
                yield grid.add_blocks (blocks);
                var drive = grid.drive;
                var drive_id = drive.id;
                disk_combo.append (drive_id, "%s (%s)".printf (drive.model.replace ("_", " "), GLib.format_size (drive.size)));
                disk_stack.add_named (grid, drive_id);
                if (disk_combo.active_id == null) {
                    disk_combo.active_id = drive_id;
                }
            }

            Idle.add (() => {
                var disk_grid = new Gtk.Grid ();
                disk_grid.orientation = Gtk.Orientation.VERTICAL;
                disk_grid.row_spacing = 12;
                disk_grid.column_spacing = 6;
                var disk_label = new Gtk.Label (_("Disk:"));
                disk_label.halign = Gtk.Align.END;
                disk_combo.halign = Gtk.Align.START;
                var multiple_os_detected = new Gtk.Label (_("Multiple operating systems were detected on your system"));
                multiple_os_detected.hexpand = true;
                multiple_os_detected.get_style_context ().add_class ("category-label");
                disk_grid.attach (multiple_os_detected, 0, 0, 2, 1);
                disk_grid.attach (disk_stack, 0, 2, 2, 1);
                disk_grid.attach (choice_grid, 0, 3, 2, 1);
                if (disk_stack.get_children ().length () > 1) {
                    disk_grid.attach (disk_label, 0, 1, 1, 1);
                    disk_grid.attach (disk_combo, 1, 1, 1, 1);
                }

                load_stack.add_named (disk_grid, "disk");
                disk_grid.show_all ();
                load_stack.set_visible_child (disk_grid);
                return Source.REMOVE;
            });
        } catch (Error e) {
            warning (e.message);
        }
    }

    public class ChoiceItem : Gtk.Grid {
        public unowned SList<Gtk.RadioButton> group;
        public ChoiceItem (string title, string subtitle, GLib.Icon icon, ChoiceItem? previous) {
            margin = 12;
            margin_start = 48;
            margin_end = 48;
            row_spacing = 6;
            column_spacing = 6;
            valign = Gtk.Align.CENTER;
            var radio = new Gtk.RadioButton (previous == null ? null : previous.group);
            group = radio.get_group ();
            var title_label = new Gtk.Label (title);
            title_label.get_style_context ().add_class ("category-label");
            title_label.xalign = 0;
            title_label.valign = Gtk.Align.END;
            var subtitle_label = new Gtk.Label (subtitle);
            subtitle_label.valign = Gtk.Align.START;
            subtitle_label.wrap = true;
            subtitle_label.xalign = 0;
            var image = new Gtk.Image.from_gicon (icon, Gtk.IconSize.DIALOG);
            attach (radio, 0, 0, 1, 2);
            attach (image, 1, 0, 1, 2);
            attach (title_label, 2, 0, 1, 1);
            attach (subtitle_label, 2, 1, 1, 1);
        }
    }
}
