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

public class Installer.InstallTypeButton : Gtk.CheckButton {
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

    class construct {
        set_accessible_role (RADIO);
    }

    construct {
        add_css_class ("image-button");

        var image = new Gtk.Image.from_icon_name (icon_name) {
            icon_size = LARGE
        };

        var title_label = new Gtk.Label (title) {
            hexpand = true,
            xalign = 0
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var subtitle_label = new Gtk.Label (subtitle) {
            wrap = true,
            xalign = 0
        };
        subtitle_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_top = 3,
            margin_end = 3,
            margin_bottom = 3,
            margin_start = 3
        };
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0);
        grid.attach (subtitle_label, 1, 1);

        child = grid;

        update_property (
            Gtk.AccessibleProperty.LABEL, title,
            Gtk.AccessibleProperty.DESCRIPTION, subtitle,
            -1
        );
    }
}
