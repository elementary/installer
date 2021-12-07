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
        var image = new Gtk.Image.from_icon_name ("utilities-system-monitor", Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.END
        };

        var heading = new Gtk.Label (_("Virtual Machine")) {
            valign = Gtk.Align.START
        };
        heading.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var primary_label = new Gtk.Label (_("You appear to be installing in a virtual machine. Some parts of %s may run slowly, freeze, or not function properly in a virtual machine. It's recommended to install on real hardware.").printf (Utils.get_pretty_name ())) {
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
        content_area.attach (image, 0, 0);
        content_area.attach (heading, 0, 1);
        content_area.attach (primary_label, 1, 0, 1, 2);

        var shutdown_button = new Gtk.Button.with_label (_("Shut Down"));
        shutdown_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        shutdown_button.clicked.connect (Utils.shutdown);

        var next_button = new Gtk.Button.with_label (_("Ignore"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        action_area.add (shutdown_button);
        action_area.add (next_button);

        shutdown_button.grab_focus ();

        next_button.clicked.connect (() => {
            next_step ();
        });

        show_all ();
    }
}
