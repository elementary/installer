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

public class Installer.ChoiceView : AbstractInstallerView {
    construct {
        var type_image = new Gtk.Image.from_icon_name (Application.get_default ().application_id) {
            pixel_size = 128
        };

        title = _("Pick your poison");

        var type_label = new Gtk.Label (title);

        // Force the user to make a conscious selection, not spam "Next"
        var no_selection = new Gtk.CheckButton () {
            active = true
        };

        var type_box = new Gtk.Box (VERTICAL, 6) {
            valign = CENTER,
            vexpand = true
        };

        var back_button = new Gtk.Button.with_label (_("Back")) {
            action_name = "win.back"
        };

        var next_button = new Gtk.Button.with_label (_("Next")) {
            sensitive = false
        };
        next_button.add_css_class (Granite.CssClass.SUGGESTED);

        action_box_end.append (back_button);
        action_box_end.append (next_button);

        next_button.clicked.connect (() => {
                next_step ();
        });

        foreach (var backend in get_backends ()) {
            var backend_button = new InstallTypeButton (
                backend.get_title (),
                Application.get_default ().application_id,
                backend.get_description ()
            ) {
                group = no_selection
            };

            backend_button.toggled.connect (() => {
                if (backend_button.active) {
                    installation_backend = backend;
                    next_button.label = backend_button.title;
                    next_button.sensitive = true;
                }
            });

            type_box.append (backend_button);
        }

        var type_scrolled = new Gtk.ScrolledWindow () {
            child = type_box,
            hscrollbar_policy = NEVER,
            propagate_natural_height = true
        };

        title_area.append (type_image);
        title_area.append (type_label);

        content_area.append (type_scrolled);
    }
}
