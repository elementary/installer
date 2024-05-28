/*-
 * Copyright 2016-2021 elementary, Inc. (https://elementary.io)
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
    private Gtk.Button next_button;
    private Gtk.Box disk_box;
    private Gtk.Stack load_stack;

    public DiskView () {
        Object (cancellable: true);
    }

    construct {
        var install_image = new Gtk.Image.from_icon_name ("drive-harddisk") {
            pixel_size = 128
        };

        var install_badge = new Gtk.Image.from_icon_name ("io.elementary.installer.emblem-downloads") {
            pixel_size = 64,
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        var image_overlay = new Gtk.Overlay () {
            child = install_image,
            valign = END
        };
        image_overlay.add_overlay (install_badge);

        var install_label = new Gtk.Label (_("Select a Drive")) {
            valign = Gtk.Align.START
        };
        install_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        var install_desc_label = new Gtk.Label (
            _("This will erase all data on the selected drive. If you have not backed your data up, you can cancel the installation and use Demo Mode.")
        ) {
            max_width_chars = 45,
            wrap = true,
            xalign = 0
        };

        disk_box = new Gtk.Box (VERTICAL, 6);

        var disk_scrolled = new Gtk.ScrolledWindow () {
            child = disk_box,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            propagate_natural_height = true
        };

        var load_spinner = new Gtk.Spinner () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        load_spinner.start ();

        var load_label = new Gtk.Label (_("Getting the current configuration…")) {
            max_width_chars = 45,
            wrap = true
        };
        load_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var load_box = new Gtk.Box (VERTICAL, 12) {
            halign = CENTER,
            valign = CENTER
        };
        load_box.append (load_spinner);
        load_box.append (load_label);

        load_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        load_stack.add_child (load_box);
        load_stack.add_named (disk_scrolled, "disk");

        var title_grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            row_spacing = 12
        };
        title_grid.attach (image_overlay, 0, 0);
        title_grid.attach (install_label, 0, 1);

        content_area.margin_start = content_area.margin_end = 12;
        content_area.column_homogeneous = true;
        content_area.valign = Gtk.Align.CENTER;
        content_area.attach (title_grid, 0, 0, 1, 2);
        content_area.attach (install_desc_label, 1, 0);
        content_area.attach (load_stack, 1, 1);

        next_button = new Gtk.Button.with_label (_("Next")) {
            // Make sure we can skip this view in Test Mode
            sensitive = Installer.App.test_mode
        };
        next_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.clicked.connect (() => ((Adw.Leaflet) get_parent ()).navigate (FORWARD));

        action_box_end.append (next_button);
    }

    public async void load (uint64 minimum_disk_size) {
        DiskButton[] enabled_buttons = {};
        DiskButton[] disabled_buttons = {};

        InstallerDaemon.DiskInfo? disks;
        try {
            disks = yield Daemon.get_default ().get_disks ();
        } catch (Error e) {
            critical ("Unable to get disks list: %s", e.message);
            load_stack.set_visible_child_name ("disk");
            return;
        }

        foreach (unowned InstallerDaemon.Disk disk in disks.physical_disks) {
            var size = disk.sectors * disk.sector_size;

            // Drives are identifiable by whether they are rotational and/or removable.
            string icon_name = null;
            if (disk.removable) {
                if (disk.rotational) {
                    icon_name = "drive-harddisk-usb";
                } else {
                    icon_name = "drive-removable-media-usb";
                }
            } else if (disk.rotational) {
                icon_name = "drive-harddisk-scsi";
            } else {
                icon_name = "drive-harddisk-solidstate";
            }

            var disk_button = new DiskButton (
                disk.name,
                icon_name,
                disk.device_path,
                size
            );

            if (size < minimum_disk_size) {
                disk_button.sensitive = false;

                disabled_buttons += disk_button;
            } else {
                disk_button.toggled.connect (() => {
                    if (disk_button.active) {
                        next_button.sensitive = true;
                    }
                });

                enabled_buttons += disk_button;
            }
        }

        // Force the user to make a conscious selection, not spam "Next"
        var no_selection = new Gtk.CheckButton () {
            active = true
        };

        foreach (DiskButton disk_button in enabled_buttons) {
            disk_button.group = no_selection;
            disk_box.append (disk_button);
        }

        foreach (DiskButton disk_button in disabled_buttons) {
            disk_button.group = no_selection;
            disk_box.append (disk_button);
        }

        load_stack.set_visible_child_name ("disk");
    }
}
