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
    public static int RESTART_TIMEOUT = 30;

    private Utils.SystemInterface system_interface;

    construct {
        try {
            system_interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
        } catch (IOError e) {
            critical (e.message);
        }

        var image = new Gtk.Image.from_icon_name ("process-completed", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Continue Setting Up"));
        title_label.halign = Gtk.Align.CENTER;
        title_label.max_width_chars = 60;
        title_label.valign = Gtk.Align.START;
        title_label.wrap = true;
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("h2");

        var primary_label = new Gtk.Label (_("Restarting in %i seconds…").printf (RESTART_TIMEOUT));
        primary_label.halign = Gtk.Align.START;
        primary_label.valign = Gtk.Align.END;
        primary_label.get_style_context ().add_class ("primary");

        var description_label = new Gtk.Label (_("Your device will automatically restart to %s to set up a new user, or you can shut down now and set a user up later.").printf (Utils.get_pretty_name ()));
        description_label.max_width_chars = 60;
        description_label.valign = Gtk.Align.START;
        description_label.wrap = true;
        description_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.column_spacing = grid.row_spacing = 12;
        grid.valign = Gtk.Align.CENTER;

        grid.attach (primary_label, 0, 0, 1, 1);
        grid.attach (description_label, 0, 1, 1, 1);

        content_area.column_homogeneous = true;
        content_area.halign = Gtk.Align.CENTER;
        content_area.margin = 48;
        content_area.margin_start = content_area.margin_end = 12;
        content_area.valign = Gtk.Align.CENTER;

        content_area.attach (image, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (grid, 1, 0, 1, 2);

        var shutdown_button = new Gtk.Button.with_label (_("Shut Down"));

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));
        restart_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (shutdown_button);
        action_area.add (restart_button);

        restart_button.clicked.connect (session_restart);

        shutdown_button.clicked.connect (() => {
            try {
                // FIXME: Disabled while in development
                // system_interface.power_off (false);
                critical ("Fake power off");
            } catch (IOError e) {
                critical (e.message);
            }
        });

        Timeout.add_seconds (RESTART_TIMEOUT, () => {
            session_restart ();
            return GLib.Source.REMOVE;
        });

        show_all ();
    }

    private void session_restart () {
        try {
            // FIXME: Disabled while in development
            // system_interface.reboot (false);
            critical ("Fake restart");
        } catch (IOError e) {
            critical (e.message);
        }
    }
}

