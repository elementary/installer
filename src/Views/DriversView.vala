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
        var image = new Gtk.Image.from_icon_name ("application-x-firmware") {
            pixel_size = 128
        };

        title = _("Additional Drivers");

        var title_label = new Gtk.Label (title);

        var description_label = new Gtk.Label (_("Broadcom® Wi-Fi adapters, NVIDIA® graphics, and some virtual machines may not function properly without additional drivers. Most devices do not require additional drivers.")) {
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };
        description_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var warning_row = new DescriptionRow (
            _("Proprietary drivers contain private code that can't be reviewed. Security and other updates are dependent on the driver vendor."),
            "security-low-symbolic",
            "yellow"
        );

        var internet_row = new DescriptionRow (
            _("An Internet connection is required to install NVIDIA® graphics drivers."),
            "network-wireless-symbolic",
            "blue"
        );

        var install_later_row = new DescriptionRow (
            _("Proprietary drivers can be installed later through AppCenter, but an Internet connection will be required for all drivers."),
            "system-software-install-symbolic",
            "purple"
        );

        var checkbutton_label = new Gtk.Label (_("Include third-party proprietary drivers when installing. I agree to their respective licenses and terms of use.")) {
            wrap = true
        };

        var drivers_check = new Gtk.CheckButton () {
            child = checkbutton_label
        };

        var message_box = new Gtk.Box (VERTICAL, 32) {
            valign = CENTER,
            vexpand = true
        };
        message_box.append (description_label);
        message_box.append (warning_row);
        message_box.append (internet_row);
        message_box.append (install_later_row);
        message_box.append (drivers_check);

        title_area.append (image);
        title_area.append (title_label);

        content_area.append (message_box);

        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.clicked.connect (() => ((Adw.Leaflet) get_parent ()).navigate (BACK));

        var next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.clicked.connect (() => next_step ());

        action_box_end.append (back_button);
        action_box_end.append (next_button);

        drivers_check.toggled.connect (() => {
            unowned var configuration = Configuration.get_default ();
            configuration.install_drivers = drivers_check.active;
        });
    }
}
