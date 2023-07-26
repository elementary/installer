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
        var image = new Gtk.Image.from_icon_name ("application-x-firmware", Gtk.IconSize.INVALID) {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Additional Drivers")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var description_label = new Gtk.Label (_("Some devices, such as NVIDIA® graphics or Broadcom® Wi-Fi adapters, may not function properly without proprietary drivers. Most devices do not require additional drivers.")) {
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };
        description_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var warning_image = new Gtk.Image.from_icon_name ("security-low-symbolic", LARGE_TOOLBAR);
        warning_image.get_style_context ().add_class ("accent");
        warning_image.get_style_context ().add_class ("yellow");

        var warning_label = new Gtk.Label (_("Proprietary drivers contain private code that can't be reviewed. Security and other updates are dependent on the driver vendor.")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var legal_image = new Gtk.Image.from_icon_name ("text-x-copying-symbolic", LARGE_TOOLBAR);
        legal_image.get_style_context ().add_class ("accent");
        legal_image.get_style_context ().add_class ("slate");

        var legal_label = new Gtk.Label (_("Proprietary drivers are subject to their own license terms. By installing, you agree to their terms of use.")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var install_later_image = new Gtk.Image.from_icon_name ("system-software-install-symbolic", LARGE_TOOLBAR);
        install_later_image.get_style_context ().add_class ("accent");
        install_later_image.get_style_context ().add_class ("purple");

        var install_later_label = new Gtk.Label (_("Proprietary drivers can be installed later through AppCenter, but this will require a working Internet connection.")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var drivers_check = new Gtk.CheckButton.with_label (_("Include third-party proprietary drivers when installing"));

        var message_grid = new Gtk.Grid () {
            valign = CENTER,
            row_spacing = 32,
            column_spacing = 12
        };
        message_grid.attach (description_label, 0, 0, 2, 1);
        message_grid.attach (warning_image, 0, 1);
        message_grid.attach (warning_label, 1, 1);
        message_grid.attach (legal_image, 0, 2);
        message_grid.attach (legal_label, 1, 2);
        message_grid.attach (install_later_image, 0, 3);
        message_grid.attach (install_later_label, 1, 3);
        message_grid.attach (drivers_check, 0, 4, 2, 1);

        content_area.column_homogeneous = true;
        content_area.margin_start = content_area.margin_end = 12;
        content_area.valign = Gtk.Align.CENTER;
        content_area.attach (image, 0, 0);
        content_area.attach (title_label, 0, 1);
        content_area.attach (message_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        var next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.clicked.connect (() => next_step ());

        action_area.add (back_button);
        action_area.add (next_button);

        drivers_check.toggled.connect (() => {
            unowned var configuration = Configuration.get_default ();
            configuration.install_drivers = drivers_check.active;
        });

        show_all ();
    }
}
