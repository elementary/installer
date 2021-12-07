/*-
 * Copyright 2021 elementary, Inc. (https://elementary.io)
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

public class VirtualMachineView : AbstractInstallerView {
    public signal void next_step ();

    construct {
        var type_image = new Gtk.Image.from_icon_name ("computer", Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.END
        };

        var type_label = new Gtk.Label (_("Speed may be limited")) {
            valign = Gtk.Align.START
        };
        type_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var primary_label = new Gtk.Label (_("We have detected that you're using a Virtual Machine. For the best experience and performance, please install %s directly on your device.").printf (Utils.get_pretty_name ())) {
            hexpand = true,
            max_width_chars = 1,
            wrap = true,
            xalign = 0
        };
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        content_area.column_homogeneous = true;
        content_area.margin_end = 12;
        content_area.margin_start = 12;
        content_area.valign = Gtk.Align.CENTER;
        content_area.attach (type_image, 0, 0);
        content_area.attach (type_label, 0, 1);
        content_area.attach (primary_label, 1, 0, 1, 2);

        var next_button = new Gtk.Button.with_label (_("Accept"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        action_area.add (next_button);

        next_button.clicked.connect (() => {
            next_step ();
        });

        show_all ();
    }
}
