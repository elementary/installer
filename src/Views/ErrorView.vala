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

public class ErrorView : AbstractInstallerView {
    private Utils.SystemInterface system_interface;

    public string log { get; construct; }

    public ErrorView (string log) {
        Object (log: log);
    }

    construct {
        try {
            system_interface = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
        } catch (IOError e) {
                warning ("%s", e.message);
        }

        var image = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Could Not Install"));
        title_label.halign = Gtk.Align.CENTER;
        title_label.max_width_chars = 60;
        title_label.valign = Gtk.Align.START;
        title_label.wrap = true;
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("h2");

        var description_label = new Gtk.Label (_("Installing %s failed, possibly due to a hardware error. Your device may not restart properly. You can try the following:").printf (Utils.get_pretty_name ()));
        description_label.max_width_chars = 60;
        description_label.wrap = true;
        description_label.xalign = 0;
        description_label.use_markup = true;

        var try_label = new Gtk.Label (_("• Try the installation again"));
        try_label.max_width_chars = 60;
        try_label.wrap = true;
        try_label.xalign = 0;
        try_label.use_markup = true;

        var launch_label = new Gtk.Label (_("• Use Demo Mode and try to manually recover"));
        launch_label.max_width_chars = 60;
        launch_label.wrap = true;
        launch_label.xalign = 0;
        launch_label.use_markup = true;

        var restart_label = new Gtk.Label (_("• Restart your device to boot from another drive"));
        restart_label.max_width_chars = 60;
        restart_label.wrap = true;
        restart_label.xalign = 0;
        restart_label.use_markup = true;

        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.attach (description_label, 0, 0, 1, 1);
        grid.attach (try_label ,        0, 1, 1, 1);
        grid.attach (launch_label,      0, 2, 1, 1);
        grid.attach (restart_label,     0, 3, 1, 1);

        var terminal_view = new Gtk.TextView ();
        terminal_view.buffer.text = log;
        terminal_view.bottom_margin = terminal_view.top_margin = terminal_view.left_margin = terminal_view.right_margin = 12;
        terminal_view.editable = false;
        terminal_view.cursor_visible = true;
        terminal_view.monospace = true;
        terminal_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        terminal_view.get_style_context ().add_class ("terminal");

        var terminal_output = new Gtk.ScrolledWindow (null, null);
        terminal_output.hscrollbar_policy = Gtk.PolicyType.NEVER;
        terminal_output.add (terminal_view);
        terminal_output.vexpand = true;
        terminal_output.hexpand = true;

        var label_area = new Gtk.Grid ();
        label_area.column_homogeneous = true;
        label_area.halign = Gtk.Align.CENTER;
        label_area.margin = 48;
        label_area.valign = Gtk.Align.CENTER;
        label_area.attach (image,       0, 0, 1, 1);
        label_area.attach (title_label, 0, 1, 1, 1);
        label_area.attach (grid,        1, 0, 1, 2);

        var content_stack = new Gtk.Stack ();
        content_stack.add (label_area);
        content_stack.add (terminal_output);

        var terminal_button = new Gtk.ToggleButton ();
        terminal_button.halign = Gtk.Align.END;
        terminal_button.image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        terminal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        content_area.attach (content_stack, 0, 0, 1, 1);

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));

        var demo_button = new Gtk.Button.with_label (_("Try Demo Mode"));

        var install_button = new Gtk.Button.with_label (_("Try Installing Again"));
        install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (terminal_button);
        action_area.add (restart_button);
        action_area.add (demo_button);
        action_area.add (install_button);

        terminal_button.toggled.connect (() => {
            if (terminal_button.active) {
                content_stack.visible_child = terminal_output;
            } else {
                content_stack.visible_child = label_area;
            }
        });

        restart_button.clicked.connect (() => {
            if (Installer.App.test_mode) {
                critical (_("Test mode reboot"));
            } else {
                try {
                    system_interface.reboot (false);
                } catch (IOError e) {
                    critical (e.message);
                }
            }
        });

        demo_button.clicked.connect (() => {
            if (Installer.App.test_mode) {
                critical (_("Test mode switch user"));
            } else {
                var seat = Utils.get_seat_instance ();
                if (seat != null) {
                    try {
                        seat.switch_to_guest ("");
                    } catch (IOError e) {
                        stderr.printf ("DisplayManager.Seat error: %s\n", e.message);
                    }
                }
            }
        });

        install_button.clicked.connect (() => {
            ((Gtk.Stack) get_parent ()).visible_child = previous_view;
        });

        show_all ();
    }
}

