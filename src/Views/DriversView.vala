/*-
 * Copyright 2023 elementary, Inc. (https://elementary.io)
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

 public class DriversView : AbstractInstallerView {
    public signal void next_step ();

    construct {
        var image = new Gtk.Image.from_icon_name ("application-x-executable", Gtk.IconSize.DIALOG) {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Install Drivers")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var description_label = new Gtk.Label (_("Proprietary drivers are required for some devices, such as Wi-Fi adapters or graphics cards, to work properly.")) {
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };
        description_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var drivers_label = new Gtk.Label (_("Install Proprietary Drivers:"));

        var drivers_switch = new Gtk.Switch ();

        var drivers_box = new Gtk.Box (HORIZONTAL, 12) {
            halign = CENTER
        };
        drivers_box.add (drivers_label);
        drivers_box.add (drivers_switch);

        var message_box = new Gtk.Box (VERTICAL, 32) {
            valign = CENTER
        };
        message_box.add (description_label);
        message_box.add (drivers_box);

        content_area.column_homogeneous = true;
        content_area.margin_start = content_area.margin_end = 12;
        content_area.valign = Gtk.Align.CENTER;
        content_area.attach (image, 0, 0);
        content_area.attach (title_label, 0, 1);
        content_area.attach (message_box, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        var next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.clicked.connect (() => next_step ());

        action_area.add (back_button);
        action_area.add (next_button);

        drivers_switch.notify["active"].connect (() => {
            unowned var configuration = Configuration.get_default ();
            configuration.install_drivers = drivers_switch.active;
        });

        show_all ();
    }
}
