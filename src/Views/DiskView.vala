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
        disk_grid.halign = Gtk.Align.CENTER;
        disk_grid.valign = Gtk.Align.CENTER;
        disk_grid.orientation = Gtk.Orientation.VERTICAL;
        disk_grid.vexpand = true;
        disk_grid.row_spacing = 6;

        var disk_scrolled = new Gtk.ScrolledWindow (null, null);
        disk_scrolled.vexpand = true;
        disk_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
#if GTK_3_22
        disk_scrolled.propagate_natural_height = true;
#endif
        disk_scrolled.add (disk_grid);

        var install_image = new Gtk.Image.from_icon_name ("system-os-installer", Gtk.IconSize.DIALOG);
        install_image.valign = Gtk.Align.START;

        var install_label = new Gtk.Label (_("Select a drive"));
        install_label.max_width_chars = 60;
        install_label.valign = Gtk.Align.START;
        install_label.get_style_context ().add_class ("h2");

        var install_desc_label = new Gtk.Label (_("This will erase all data on the selected drive. If you have not backed your data up, you can cancel the installation and use Demo Mode."));
        install_desc_label.hexpand = true;
        install_desc_label.max_width_chars = 60;
        install_desc_label.wrap = true;

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

        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("disks");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        content_area.attach (artwork, 0, 0, 1, 1);
        content_area.attach (install_label, 0, 1, 1, 1);
        content_area.attach (load_stack, 1, 0, 1, 2);

        next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;
        next_button.clicked.connect (() => next_step ());

        action_area.add (next_button);

        show_all ();
    }

    // If possible, open devices in a different thread so that the interface stays awake.
    public async void load (uint64 minimum_disk_size) {
        DiskButton[] enabled_buttons = {};
        DiskButton[] disabled_buttons = {};

        unowned Distinst.InstallOptions install_options = InstallOptions.get_default ().get_updated_options ();

        if (install_options == null) {
            critical (_("unable to get installation options"));
            return;
        }

        foreach (unowned Distinst.EraseOption disk in install_options.get_erase_options ()) {
            var size = disk.get_sectors () * 512;
            string model = Utils.string_from_utf8 (disk.get_model ());
            string path = Utils.string_from_utf8 (disk.get_device_path ());
            string icon_name = Utils.string_from_utf8 (disk.get_linux_icon ());

            var disk_button = new DiskButton (
                model,
                icon_name,
                path,
                size
            );

            if (disk.meets_requirements ()) {
                disk_button.clicked.connect (() => {
                    if (disk_button.active) {
                        disk_grid.get_children ().foreach ((child) => {
                            ((Gtk.ToggleButton)child).active = child == disk_button;
                        });

                        var opts = InstallOptions.get_default ();

                        if (opts.has_recovery ()) {
                            unowned Distinst.InstallOptions options = opts.get_options ();
                            var recovery = options.get_recovery_option ();

                            InstallOptions.get_default ().selected_option = new Distinst.InstallOption () {
                                tag = Distinst.InstallOptionVariant.RECOVERY,
                                option = (void*) recovery,
                                encrypt_pass = null
                            };
                        } else {
                            InstallOptions.get_default ().selected_option = new Distinst.InstallOption () {
                                tag = Distinst.InstallOptionVariant.ERASE,
                                option = (void*) disk,
                                encrypt_pass = null
                            };
                        }

                        next_button.sensitive = true;
                    } else {
                        next_button.sensitive = false;
                    }
                });

                enabled_buttons += disk_button;
            } else {
                disk_button.set_sensitive (false);

                disabled_buttons += disk_button;
            }
        }

        foreach (DiskButton disk_button in enabled_buttons) {
            disk_grid.add (disk_button);
        }

        foreach (DiskButton disk_button in disabled_buttons) {
            disk_grid.add (disk_button);
        }

        disk_grid.show_all ();
        load_stack.set_visible_child_name ("disk");
    }
}
