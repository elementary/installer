// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
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

public class TryInstallView : AbstractInstallerView {
    public signal void next_step ();

    // replace this with actual content when the type is ready.

    construct {
        var title_label = new Gtk.Label (_("Install OS"));
        title_label.get_style_context ().add_class ("h1");
        title_label.valign = Gtk.Align.START;

        var description_label = new Gtk.Label (_("You can install OS on this device now, or cancel the installation to try it without installing. "));
        description_label.valign = Gtk.Align.START;
        description_label.hexpand = true;

        var nochanges_label = new Gtk.Label (_("Data from your previous operating system is unchanged until you install OS"));
        nochanges_label.valign = Gtk.Align.START;
        nochanges_label.wrap = true;

        var nochanges_image = new Gtk.Image.from_icon_name ("checkmark", Gtk.IconSize.DIALOG);
        nochanges_image.valign = Gtk.Align.START;

        var nosaving_label = new Gtk.Label (_("Any changes you make in OS before installing will not be saved"));
        nosaving_label.valign = Gtk.Align.START;
        nosaving_label.wrap = true;

        var nosaving_image = new Gtk.Image.from_icon_name ("edit-undo", Gtk.IconSize.DIALOG);
        nosaving_image.valign = Gtk.Align.START;

        var return_label = new Gtk.Label (_("If you cancel, you can always return to the installer by selecting the Install OS icon"));
        return_label.valign = Gtk.Align.START;
        return_label.wrap = true;

        var return_image = new Gtk.Image.from_icon_name ("system-os-installer", Gtk.IconSize.DIALOG);
        return_image.valign = Gtk.Align.END;

        var help_grid = new Gtk.Grid ();
        help_grid.orientation = Gtk.Orientation.VERTICAL;
        help_grid.column_homogeneous = true;
        help_grid.vexpand = true;
        help_grid.margin_end = 10;
        help_grid.margin_start = 10;
        help_grid.row_spacing = 10;
        help_grid.
        help_grid.attach (nochanges_image, 0, 0, 1, 1);
        help_grid.attach (nochanges_label, 0, 1, 1, 1);
        help_grid.attach (nosaving_image, 1, 0, 1, 1);
        help_grid.attach (nosaving_label, 1, 1, 1, 1);
        help_grid.attach (return_image, 2, 0, 1, 1);
        help_grid.attach (return_label, 2, 1, 1, 1);



        content_area.column_homogeneous = true;
        content_area.margin_end = 10;
        content_area.margin_start = 10;
        content_area.attach (title_label, 0, 0, 1, 1);
        content_area.attach (description_label, 0, 1, 1, 1);
        content_area.attach (help_grid, 0, 2, 1, 1);

        var cancel_button = new Gtk.Button.with_label (_("Cancel installation"));

        var next_button = new Gtk.Button.with_label (_("Install OS"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (cancel_button);
        action_area.add (next_button);

        cancel_button.clicked.connect (() => cancel ());
        next_button.clicked.connect (() => next_step ());
    }

    private class LayoutRow : Gtk.ListBoxRow {
        public LayoutRow (string name) {
            var label = new Gtk.Label (name);
            label.margin = 6;
            label.xalign = 0;
            label.get_style_context ().add_class ("h3");
            add (label);
        }
    }
}
