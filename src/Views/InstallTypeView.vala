// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Cassidy James Blaede <c@ssidyjam.es>
 */

public class Installer.InstallTypeView : AbstractInstallerView {
    public signal void custom_step ();
    public signal void next_step ();

    private Gtk.Button next_button;
    private Gtk.Grid type_grid;

    // public InstallTypeView () {
    //     Object (cancellable: true);
    // }

    construct {
        type_grid = new Gtk.Grid ();
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

        var type_label = new Gtk.Label (_("Install Type"));
        type_label.hexpand = true;
        type_label.get_style_context ().add_class ("h2");

        var type_desc_label = new Gtk.Label (_("Choose how you would like to install %s.".printf (Utils.get_pretty_name ())));
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

        var custom_button = new Gtk.Button.with_label (_("Customize Partitions…"));
        custom_button.clicked.connect (() => custom_step ());
        action_area.add (custom_button);
        action_area.set_child_secondary (custom_button, true);
        action_area.set_child_non_homogeneous (custom_button, true);

        next_button = new Gtk.Button.with_label (_("Continue"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        // next_button.sensitive = false;
        next_button.clicked.connect (() => next_step ());

        action_area.add (next_button);

        // TODO: Iterate through possible options, add a button for each.
        var clean_install_button = new InstallTypeButton (
            "Clean Install",
            "system-os-installer",
            "Erase everything and start fresh"
        );
        type_grid.add (install_type_button);

        var custom_button = new InstallTypeButton (
            "Custom…",
            "system-os-installer",
            "Manually define partitions, dual boot, etc."
        );
        type_grid.add (install_type_button);

        show_all ();
    }
}
