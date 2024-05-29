/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class DescriptionRow : Gtk.Box {
    public string description { get; construct; }
    public string icon_name { get; construct; }
    public string color { get; construct; }

    public DescriptionRow (string description, string icon_name, string color) {
        Object (
            color: color,
            description: description,
            icon_name: icon_name
        );
    }

    construct {
        var image = new Gtk.Image.from_icon_name (icon_name) {
            pixel_size = 24,
            valign = START
        };
        image.add_css_class (Granite.STYLE_CLASS_ACCENT);
        image.add_css_class (color);

        var description_label = new Gtk.Label (description) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            use_markup = true,
            wrap = true,
            xalign = 0
        };

        spacing = 12;
        append (image);
        append (description_label);
    }
}
