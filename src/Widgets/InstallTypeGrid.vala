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

public class Installer.InstallTypeButton : Gtk.ToggleButton {
    public string type_title { get; construct; }
    public string icon_name { get; construct; }
    public string type_subtitle { get; construct; }

    public InstallTypeButton (string type_title, string icon_name, string type_subtitle) {
        Object (
            type_title: type_title,
            icon_name: icon_name,
            type_subtitle: type_subtitle
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var type_image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        type_image.use_fallback = true;

        var title_label = new Gtk.Label (type_title);
        title_label.halign = Gtk.Align.START;
        title_label.hexpand = true;
        title_label.valign = Gtk.Align.END;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var subtitle_label = new Gtk.Label ("%s".printf (type_subtitle));
        subtitle_label.halign = Gtk.Align.START;
        subtitle_label.use_markup = true;
        subtitle_label.max_width_chars = 45;
        subtitle_label.valign = Gtk.Align.START;
        subtitle_label.wrap = true;
        subtitle_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.margin_end = 12;
        grid.column_spacing = 6;
        grid.row_spacing = 6;
        grid.orientation = Gtk.Orientation.VERTICAL;

        grid.attach (type_image,     0, 0, 1, 2);
        grid.attach (title_label,    1, 0);
        grid.attach (subtitle_label, 1, 1);

        add (grid);
    }
}

