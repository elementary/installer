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
 *
 */

public class EndSessionDialog : Gtk.Dialog {
    public EndSessionDialog () {
        Object (
            title: "",
            deletable: false,
            resizable: false,
            skip_taskbar_hint: true,
            skip_pager_hint: true
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("system-shutdown", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (_("Are you sure you want to Shut Down?"));
        primary_label.max_width_chars = 50;
        primary_label.selectable = true;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class ("primary");

        var secondary_label = new Gtk.Label (_("This will cancel installation and turn off this device."));
        secondary_label.max_width_chars = 50;
        secondary_label.selectable = true;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.margin_start = grid.margin_end = 12;
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0, 1, 1);
        grid.attach (secondary_label, 1, 1, 1, 1);
        grid.show_all ();

        get_content_area ().add (grid);

        var restart_button = (Gtk.Button) add_button (_("Restart"), Gtk.ResponseType.OK);

        var cancel_button = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var shutdown_button = (Gtk.Button) add_button (_("Shut Down"), Gtk.ResponseType.OK);
        shutdown_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var action_area = get_action_area ();
        action_area.margin = 6;
        action_area.margin_top = 12;

        set_keep_above (true);
        stick ();

        restart_button.clicked.connect (Utils.restart);
        cancel_button.clicked.connect (() => destroy ());
        shutdown_button.clicked.connect (Utils.shutdown);
    }
}
