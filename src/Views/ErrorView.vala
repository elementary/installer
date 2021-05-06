/*-
 * Copyright 2017–2021 elementary, Inc. (https://elementary.io)
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
    public string log { get; construct; }

    public ErrorView (string log) {
        Object (log: log);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG) {
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Could Not Install")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var description_label = new Gtk.Label (_("Installing %s failed, possibly due to a hardware error. The device may not restart properly. You can try the following:").printf (Utils.get_pretty_name ())) {
            margin_bottom = 12,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var redo_image = new Gtk.Image.from_icon_name ("edit-undo-symbolic", Gtk.IconSize.MENU) {
            margin_start = 6
        };

        var try_label = new Gtk.Label (_("Try the installation again")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var demo_image = new Gtk.Image.from_icon_name ("document-properties-symbolic", Gtk.IconSize.MENU) {
            margin_start = 6
        };

        var launch_label = new Gtk.Label (_("Use Demo Mode and try to manually recover")) {
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var restart_image = new Gtk.Image.from_icon_name ("system-reboot-symbolic", Gtk.IconSize.MENU) {
            margin_start = 6
        };

        var restart_label = new Gtk.Label (_("Restart the device and boot from another drive")) {
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var terminal_button = new Gtk.ToggleButton () {
            always_show_image = true,
            halign = Gtk.Align.START,
            image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            label = _("Details"),
            margin_top = 12
        };
        terminal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var buffer = new Gtk.TextBuffer (null) {
            text = log
        };

        var terminal_view = new Installer.Terminal (buffer);

        var terminal_revealer = new Gtk.Revealer ();
        terminal_revealer.add (terminal_view);

        var grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 12,
            valign = Gtk.Align.CENTER
        };
        grid.attach (description_label, 0, 0, 2);
        grid.attach (redo_image, 0, 1);
        grid.attach (try_label, 1, 1);
        grid.attach (demo_image, 0, 2);
        grid.attach (launch_label, 1, 2);
        grid.attach (restart_image, 0, 3);
        grid.attach (restart_label, 1, 3);
        grid.attach (terminal_button, 0, 4, 2);
        grid.attach (terminal_revealer, 0, 5, 2);

        content_area.column_homogeneous = true;
        content_area.margin_start = content_area.margin_end = 12;
        content_area.attach (image, 0, 0);
        content_area.attach (title_label, 0, 1);
        content_area.attach (grid, 1, 0, 1, 2);

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));

        var demo_button = new Gtk.Button.with_label (_("Try Demo Mode"));

        var install_button = new Gtk.Button.with_label (_("Try Installing Again"));
        install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (restart_button);
        action_area.add (demo_button);
        action_area.add (install_button);

        restart_button.clicked.connect (Utils.restart);

        demo_button.clicked.connect (Utils.demo_mode);

        install_button.clicked.connect (() => {
            ((Gtk.Stack) get_parent ()).visible_child = previous_view;
        });

        terminal_button.toggled.connect (() => {
            terminal_revealer.reveal_child = terminal_button.active;
            if (terminal_button.active) {
                terminal_view.attempt_scroll ();
            }
        });

        show_all ();
    }
}
