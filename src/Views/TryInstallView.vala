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
        var title_label = new Gtk.Label (_("Welcome"));
        title_label.get_style_context ().add_class ("h2");
        title_label.valign = Gtk.Align.START;

        var description_label = new Gtk.Label (_("You can try out OS_NAME before you install it. If you're ready, you can install it any time."));
        title_label.valign = Gtk.Align.START;

        var image = new Gtk.Image.from_icon_name ("distributor-logo", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        var selection_grid = new Gtk.Grid ();
        selection_grid.orientation = Gtk.Orientation.VERTICAL;
        selection_grid.add (description_label);
        selection_grid.add (image);

        content_area.column_homogeneous = true;
        content_area.margin_end = 10;
        content_area.margin_start = 10;
        content_area.attach (image, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (selection_grid, 0, 1, 1, 1);

        var cancel_button = new Gtk.Button.with_label (_("Cancel installation"));

        var next_button = new Gtk.Button.with_label (_("Install OS_NAME"));
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
