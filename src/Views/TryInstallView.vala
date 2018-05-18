// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017–2018 elementary LLC. (https://elementary.io)
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
 */

public class Installer.TryInstallView : AbstractInstallerView {
    public signal void custom_step ();
    public signal void next_step ();

    private Gtk.Button next_button;

    construct {
        var type_grid = new Gtk.Grid ();
        type_grid.halign = Gtk.Align.CENTER;
        type_grid.valign = Gtk.Align.CENTER;
        type_grid.orientation = Gtk.Orientation.VERTICAL;
        type_grid.vexpand = true;
        type_grid.row_spacing = 6;

        var type_scrolled = new Gtk.ScrolledWindow (null, null);
        type_scrolled.vexpand = true;
        type_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
#if GTK_3_22
        type_scrolled.propagate_natural_height = true;
#endif
        type_scrolled.add (type_grid);

        var type_image = new Gtk.Image.from_icon_name ("system-os-installer", Gtk.IconSize.DIALOG);
        type_image.valign = Gtk.Align.START;

        var type_label = new Gtk.Label (_("Try or Install"));
        type_label.hexpand = true;
        type_label.get_style_context ().add_class ("h2");

        var type_desc_label = new Gtk.Label (_("You can install %s on this device now, or try Demo Mode without installing.").printf (Utils.get_pretty_name ()));
        type_desc_label.hexpand = true;
        type_desc_label.max_width_chars = 60;
        type_desc_label.wrap = true;

        var title_grid = new Gtk.Grid ();
        title_grid.column_spacing = 12;
        title_grid.row_spacing = 6;
        title_grid.halign = Gtk.Align.CENTER;
        title_grid.valign = Gtk.Align.CENTER;
        title_grid.attach (type_image, 0, 0, 1, 1);
        title_grid.attach (type_label, 0, 1, 1, 1);
        title_grid.attach (type_desc_label, 0, 2, 1, 1);

        content_area.valign = Gtk.Align.FILL;
        content_area.column_homogeneous = true;
        content_area.attach (title_grid, 0, 0, 1, 1);
        content_area.attach (type_scrolled, 1, 0, 1, 1);

        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        next_button = new Gtk.Button.with_label (_("Next"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.sensitive = false;

        var shutdown_button = new Gtk.Button.from_icon_name ("system-shutdown-symbolic", Gtk.IconSize.BUTTON);
        shutdown_button.tooltip_text = _("Shut Down");
        shutdown_button.get_style_context ().add_class ("circular");

        var demo_button = new InstallTypeButton (
            _("Try Demo Mode"),
            "dialog-question",
            _("Changes will not be saved, and data from your previous OS will be unchanged. Performance and features may not reflect the installed experience.")
        );

        var clean_install_button = new InstallTypeButton (
            _("Clean Install"),
            "edit-clear",
            _("Erase everything and install a fresh copy of %s.").printf (Utils.get_pretty_name ())
        );

        var custom_button = new InstallTypeButton (
            _("Custom (Advanced)"),
            "system-run",
            _("Create, resize, or otherwise manage partitions manually. This method may lead to data loss.")
        );

        action_area.add (shutdown_button);
        action_area.add (back_button);
        action_area.add (next_button);
        action_area.set_child_secondary (shutdown_button, true);
        action_area.set_child_non_homogeneous (shutdown_button, true);

        type_grid.add (demo_button);
        type_grid.add (clean_install_button);
        type_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        type_grid.add (custom_button);

        demo_button.clicked.connect (() => {
            if (demo_button.active) {
                type_grid.get_children ().foreach ((child) => {
                    if (child is Gtk.ToggleButton) {
                        ((Gtk.ToggleButton)child).active = child == demo_button;
                    }
                });

                next_button.label = demo_button.type_title;
                next_button.sensitive = true;
                next_button.clicked.connect (Utils.demo_mode);
            } else {
                next_button.sensitive = false;
                next_button.label = _("Next");
            }
        });

        clean_install_button.clicked.connect (() => {
            if (clean_install_button.active) {
                type_grid.get_children ().foreach ((child) => {
                    if (child is Gtk.ToggleButton) {
                        ((Gtk.ToggleButton)child).active = child == clean_install_button;
                    }
                });

                next_button.label = clean_install_button.type_title;
                next_button.sensitive = true;
                next_button.clicked.connect (() => next_step ());
            } else {
                next_button.sensitive = false;
                next_button.label = _("Next");
            }
        });

        custom_button.clicked.connect (() => {
            if (custom_button.active) {
                type_grid.get_children ().foreach ((child) => {
                    if (child is Gtk.ToggleButton) {
                        ((Gtk.ToggleButton)child).active = child == custom_button;
                    }
                });

                next_button.label = custom_button.type_title;
                next_button.sensitive = true;
                next_button.clicked.connect (() => custom_step ());
            } else {
                next_button.sensitive = false;
                next_button.label = _("Next");
            }
        });

        show_all ();
    }
}

