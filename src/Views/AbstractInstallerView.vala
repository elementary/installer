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

public abstract class AbstractInstallerView : Gtk.Grid {
    public signal void cancel ();
    public bool cancellable { get; construct; }

    protected Gtk.Grid content_area;
    protected Gtk.ButtonBox action_area;

    public AbstractInstallerView (bool cancellable = false) {
        Object (
            cancellable: cancellable,
            row_spacing: 24
        );
    }
    
    construct {
        content_area = new Gtk.Grid ();
        content_area.column_spacing = 12;
        content_area.row_spacing = 12;
        content_area.expand = true;
        content_area.orientation = Gtk.Orientation.VERTICAL;

        action_area = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        action_area.margin_end = 10;
        action_area.spacing = 6;
        action_area.layout_style = Gtk.ButtonBoxStyle.END;

        if (cancellable) {
            var cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
            cancel_button.clicked.connect (() => {
                get_toplevel ().destroy ();
            });

            action_area.add (cancel_button);
        }

        orientation = Gtk.Orientation.VERTICAL;
        add (content_area);
        add (action_area);
    }
}
