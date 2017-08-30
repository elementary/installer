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

public class Installer.DiskView : AbstractInstallerView {
    public signal void next_step ();

    private Gtk.Stack load_stack;
    private Gtk.Stack disk_stack;
    private Gtk.ComboBoxText disk_combo;
    private Gtk.Button next_button;

    construct {
        var load_spinner = new Gtk.Spinner ();
        load_spinner.width_request = 48;
        load_spinner.height_request = 48;
        load_spinner.start ();

        var load_label = new Gtk.Label (_("Getting the current configuration…"));
        load_label.get_style_context ().add_class ("h2");

        var load_grid = new Gtk.Grid ();
        load_grid.row_spacing = 12;
        load_grid.expand = true;
        load_grid.orientation = Gtk.Orientation.VERTICAL;
        load_grid.valign = Gtk.Align.CENTER;
        load_grid.halign = Gtk.Align.CENTER;
        load_grid.add (load_spinner);
        load_grid.add (load_label);

        load_stack = new Gtk.Stack ();
        load_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        load_stack.add_named (load_grid, "loading");

        content_area.add (load_stack);

        disk_stack = new Gtk.Stack ();
        disk_stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;

        disk_combo = new Gtk.ComboBoxText ();
        disk_combo.changed.connect (() => {
            disk_stack.set_visible_child_name (disk_combo.active_id);
        });

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/pantheon/installer/icons/os");

        next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.clicked.connect (() => next_step ());

        var cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
        cancel_button.clicked.connect (() => cancel ());

        action_area.add (cancel_button);
        action_area.add (next_button);
        show_all ();
    }

    // If possible, open devices in a different thread so that the interface stays awake.
    public async void load () {
        var disks = yield Installer.Disk.get_disks ();
        foreach (var disk in disks) {
            DiskGrid grid = null;
            var partitions = disk.partitions;
            foreach (var partition in partitions) {
                if (partition == null) {
                    warning ("OHHHH");
                    continue;
                }
                string name;
                string? version;
                GLib.Icon icon;
                if (yield partition.detect_operating_system (out name, out version, out icon)) {
                    if (grid == null) {
                        grid = new DiskGrid (disk);
                        var disk_id = disk.get_id ();
                        disk_combo.append (disk_id, "%s (%s)".printf (disk.get_label_name (), GLib.format_size (disk.get_size ())));
                        disk_stack.add_named (grid, disk_id);
                        if (disk_combo.active_id == null) {
                            disk_combo.active_id = disk_id;
                        }
                    }

                    grid.add_button (name, version, icon, partition);
                }
                
            }
        }

        Idle.add (() => {
            var disk_label = new Gtk.Label (_("Disk:"));
            disk_label.halign = Gtk.Align.END;
            disk_combo.halign = Gtk.Align.START;

            var multiple_os_detected = new Gtk.Label (_("Multiple disks were detected on your system"));
            multiple_os_detected.hexpand = true;
            multiple_os_detected.get_style_context ().add_class ("category-label");

            var disk_grid = new Gtk.Grid ();
            disk_grid.orientation = Gtk.Orientation.VERTICAL;
            disk_grid.row_spacing = 12;
            disk_grid.column_spacing = 6;
            if (disk_stack.get_children ().length () > 1) {
                disk_grid.attach (disk_label, 0, 1, 1, 1);
                disk_grid.attach (disk_combo, 1, 1, 1, 1);
            }

            // Check for multiple OS across all the disks.
            int number = 0;
            disk_stack.get_children ().foreach ((child) => {
                number += ((DiskGrid)child).buttons.size;
            });

            if (number > 1) {
                disk_grid.attach (multiple_os_detected, 0, 0, 2, 1);
                disk_grid.attach (disk_stack, 0, 2, 2, 1);
            }

            load_stack.add_named (disk_grid, "disk");
            disk_grid.show_all ();
            load_stack.set_visible_child (disk_grid);
            return Source.REMOVE;
        });
    }
}
