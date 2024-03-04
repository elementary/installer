/*-
 * Copyright 2018-2021 elementary, Inc. (https://elementary.io)
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

public class Installer.InstallTypeButton : Gtk.RadioButton {
    public string title { get; construct; }
    public string icon_name { get; construct; }
    public string subtitle { get; construct; }

    public InstallTypeButton (string title, string icon_name, string subtitle) {
        Object (
            title: title,
            icon_name: icon_name,
            subtitle: subtitle
        );
    }

    construct {
        get_style_context ().add_class ("image-button");

        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);

        var title_label = new Gtk.Label (title) {
            hexpand = true,
            xalign = 0
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var subtitle_label = new Gtk.Label (subtitle) {
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var grid = new Gtk.Grid () {
            column_spacing = 3,
            row_spacing = 6,
            margin_top = 3,
            margin_end = 3,
            margin_bottom = 3,
            margin_start = 3
        };
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0);
        grid.attach (subtitle_label, 1, 1);

        add (grid);
    }
}
