// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
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

public class SuccessView : AbstractInstallerView {
    private Utils.SystemInterface system_interface;

    construct {
        try {
            system_interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
        } catch (IOError e) {
            critical (e.message);
        }

        var image = new Gtk.Image.from_icon_name ("process-completed", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (_("Restart your device to continue setting up"));
        primary_label.max_width_chars = 60;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class ("h2");

        var secondary_label = new Gtk.Label (_("Your device will automatically restart to %s in 30 seconds to set up a new user, or you can shut down now and set a user up later.").printf (Utils.get_pretty_name ()));
        secondary_label.max_width_chars = 60;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        content_area.halign = Gtk.Align.CENTER;
        content_area.valign = Gtk.Align.CENTER;
        content_area.margin_end = 22;
        content_area.margin_start = 22;
        content_area.row_spacing = 6;
        content_area.attach (image, 0, 0, 1, 2);
        content_area.attach (primary_label, 1, 0, 1, 1);
        content_area.attach (secondary_label, 1, 1, 1, 1);

        var shutdown_button = new Gtk.Button.with_label (_("Shut Down"));

        var restart_button = new Gtk.Button.with_label (_("Restart"));
        restart_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (shutdown_button);
        action_area.add (restart_button);

        restart_button.clicked.connect (session_restart);

        shutdown_button.clicked.connect (() => {
            try {
                system_interface.power_off (false);
            } catch (IOError e) {
                critical (e.message);
            }
        });

        Timeout.add_seconds (30, () => {
            session_restart ();
            return GLib.Source.REMOVE;
        });

        show_all ();
    }

    private void session_restart () {
        try {
            system_interface.reboot (false);
        } catch (IOError e) {
            critical (e.message);
        }
    }
}

