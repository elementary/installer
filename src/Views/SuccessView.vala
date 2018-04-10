// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017–2018 elementary LLC. (https://elementary.io)
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
    public static int RESTART_TIMEOUT = 30;

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
        primary_label.max_width_chars = 30;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class ("h2");

        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("success");
        artwork.get_style_context().add_class ("artwork");
        artwork.vexpand = true;
        artwork.hexpand = true;

        content_area.attach (artwork, 0, 0, 1, 2);
        content_area.attach (primary_label, 1, 0, 1, 1);

        var shutdown_button = new Gtk.Button.with_label (_("Shut Down"));

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));
        restart_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (shutdown_button);
        action_area.add (restart_button);

        restart_button.clicked.connect (session_restart);

        shutdown_button.clicked.connect (() => {
            if (Installer.App.test_mode) {
                critical (_("Test mode shutdown"));
            } else {
                try {
                    system_interface.power_off (false);
                } catch (IOError e) {
                    critical (e.message);
                }
            }
        });

        // Timeout.add_seconds (RESTART_TIMEOUT, () => {
        //     session_restart ();
        //     return GLib.Source.REMOVE;
        // });

        show_all ();
    }

    private void session_restart () {
        if (Installer.App.test_mode) {
            critical (_("Test mode reboot"));
        } else {
            try {
                system_interface.reboot (false);
            } catch (IOError e) {
                critical (e.message);
            }
        }
    }
}

