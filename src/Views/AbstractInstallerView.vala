/*-
 * Copyright 2017–2021 elementary, Inc. (https://elementary.io)
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

public abstract class AbstractInstallerView : Gtk.Box {
    public bool cancellable { get; construct; }

    public signal void cancel ();

    protected Gtk.Grid content_area;
    protected Gtk.Box action_box_start;
    protected Gtk.Box action_box_end;

    protected AbstractInstallerView (bool cancellable = false) {
        Object (cancellable: cancellable);
    }

    construct {
        content_area = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12,
            hexpand = true,
            vexpand = true,
            orientation = Gtk.Orientation.VERTICAL
        };

        action_box_end = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            hexpand = true,
            homogeneous = true
        };

        action_box_start = new Gtk.Box (HORIZONTAL, 6) {
            homogeneous = true
        };

        var action_area = new Gtk.Box (HORIZONTAL, 12) {
            margin_start = 10,
            margin_end = 10
        };
        action_area.add (action_box_start);
        action_area.add_css_class ("button-box");

        if (Installer.App.test_mode) {
            var test_label = new Gtk.Label (_("Test Mode"));
            test_label.add_css_class (Gtk.STYLE_CLASS_ERROR);

            action_area.add (test_label);
        }

        action_area.add (action_box_end);

        if (cancellable) {
            var cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
            cancel_button.clicked.connect (() => {
                cancel ();
            });

            action_box_end.append (cancel_button);
        }

        orientation = VERTICAL;
        spacing = 24;
        margin_top = 12;
        margin_bottom = 12;
        add (content_area);
        add (action_area);
    }
}
