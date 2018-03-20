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

    private Gtk.Button next_button;
    private Gtk.Grid disk_grid;
    private Gtk.Stack load_stack;

    public DiskView () {
        Object (cancellable: true);
    }

    construct {
        disk_grid = new Gtk.Grid ();
        disk_grid.column_spacing = 12;
        disk_grid.halign = Gtk.Align.CENTER;
        disk_grid.orientation = Gtk.Orientation.HORIZONTAL;

        var disk_scrolled = new Gtk.ScrolledWindow (null, null);
        disk_scrolled.hexpand = true;
        disk_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
#if GTK_3_22
        disk_scrolled.propagate_natural_height = true;
#endif
        disk_scrolled.add (disk_grid);

        var install_image = new Gtk.Image.from_icon_name ("system-os-installer", Gtk.IconSize.DIALOG);
        install_image.valign = Gtk.Align.START;

        var install_label = new Gtk.Label (_("Select a drive to use for installation"));
        install_label.hexpand = true;
        install_label.get_style_context ().add_class ("h2");
        install_label.xalign = 0;

        var install_desc_label = new Gtk.Label (_("This will erase all data on the selected drive. If you have not backed your data up, you can cancel the installation and use Demo Mode."));
        install_desc_label.hexpand = true;
        install_desc_label.max_width_chars = 60;
        install_desc_label.wrap = true;
        install_desc_label.xalign = 0;

        var load_spinner = new Gtk.Spinner ();
        load_spinner.halign = Gtk.Align.CENTER;
        load_spinner.valign = Gtk.Align.CENTER;
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
        load_stack.add_named (disk_scrolled, "disk");

        var title_grid = new Gtk.Grid ();
        title_grid.column_spacing = 12;
        title_grid.row_spacing = 6;
        title_grid.halign = Gtk.Align.CENTER;
        title_grid.attach (install_image, 0, 0, 1, 2);
        title_grid.attach (install_label, 1, 0, 1, 1);
        title_grid.attach (install_desc_label, 1, 1, 1, 1);

        content_area.valign = Gtk.Align.CENTER;
        content_area.attach (title_grid, 0, 0, 1, 1);
        content_area.attach (load_stack, 0, 1, 1, 1);

        next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;
        next_button.clicked.connect (() => next_step ());

        action_area.add (next_button);

        show_all ();
    }

    // If possible, open devices in a different thread so that the interface stays awake.
    public async void load () {
        Distinst.Disks disks = Distinst.Disks.probe ();
        foreach (unowned Distinst.Disk disk in disks.list ()) {
            if (disk.contains_mount ("/") || disk.contains_mount ("/cdrom")) {
                continue;
            }

            // Drives are identifiable by whether they are rotational and/or removable.
            string icon_name = null;
            if (disk.is_removable ()) {
                if (disk.is_rotational ()) {
                    icon_name = "drive-harddisk-usb";
                } else {
                    icon_name = "drive-removable-media-usb";
                }
            } else if (disk.is_rotational ()) {
                icon_name = "drive-harddisk-scsi";
            } else {
                icon_name = "drive-harddisk-solidstate";
            }

            // NOTE: Why does casting as a string not work?
            uint8[] raw_path = disk.get_device_path ();
            var path_builder = new GLib.StringBuilder.sized (raw_path.length);
            foreach (uint8 byte in raw_path) {
                path_builder.append_c ((char) byte);
            }

            var disk_button = new DiskButton (
                disk.get_serial ().replace ("_", " "),
                icon_name,
                (owned) path_builder.str,
                disk.get_sectors () * disk.get_sector_size ()
            );

            disk_grid.add (disk_button);
            disk_button.clicked.connect (() => {
                if (disk_button.active) {
                    disk_grid.get_children ().foreach ((child) => {
                        ((Gtk.ToggleButton)child).active = child == disk_button;
                    });

                    next_button.sensitive = true;
                } else {
                    next_button.sensitive = false;
                }
            });
        }

        disk_grid.show_all ();
        load_stack.set_visible_child_name ("disk");
    }
}
