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

    protected Gtk.Box title_area;
    protected Gtk.Box content_area;
    protected Gtk.Box action_box_start;
    protected Gtk.Box action_box_end;

    protected AbstractInstallerView (bool cancellable = false) {
        Object (cancellable: cancellable);
    }

    construct {
        title_area = new Gtk.Box (VERTICAL, 12) {
            valign = CENTER
        };
        title_area.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        content_area = new Gtk.Box (VERTICAL, 24);

        var box = new Gtk.Box (HORIZONTAL, 12) {
            homogeneous = true,
            hexpand = true,
            vexpand = true,
        };
        box.append (title_area);
        box.append (content_area);

        action_box_end = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            hexpand = true,
            homogeneous = true
        };

        action_box_start = new Gtk.Box (HORIZONTAL, 6) {
            homogeneous = true
        };

        var action_area = new Gtk.Box (HORIZONTAL, 12);
        action_area.append (action_box_start);
        action_area.add_css_class ("button-box");

        if (Installer.App.test_mode) {
            var test_label = new Gtk.Label (_("Test Mode"));
            test_label.add_css_class (Granite.STYLE_CLASS_ERROR);

            action_area.append (test_label);
        }

        action_area.append (action_box_end);

        if (cancellable) {
            var cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
            cancel_button.clicked.connect (() => {
                cancel ();
            });

            action_box_end.append (cancel_button);
        }

        var main_box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        main_box.append (box);
        main_box.append (action_area);

        append (main_box);
    }
}
