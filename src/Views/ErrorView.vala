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

public class ErrorView : AbstractInstallerView {
    public string log { get; construct; }

    public ErrorView (string log) {
        Object (log: log);
    }

    construct {
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

        var terminal_button = new Gtk.ToggleButton ();
        terminal_button.always_show_image = true;
        terminal_button.halign = Gtk.Align.START;
        terminal_button.label = _("Details");
        terminal_button.margin_top = 18;
        terminal_button.image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        terminal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var buffer = new Gtk.TextBuffer (null);
        buffer.text = log;

        var terminal_view = new Installer.Terminal (buffer);

        var terminal_revealer = new Gtk.Revealer ();
        terminal_revealer.add (terminal_view);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 6;
        grid.valign = Gtk.Align.CENTER;
        grid.add (description_label);
        grid.add (try_label);
        grid.add (launch_label);
        grid.add (restart_label);
        grid.add (terminal_button);
        grid.add (terminal_revealer);

        content_area.column_homogeneous = true;
        content_area.halign = Gtk.Align.CENTER;
        content_area.margin = 48;
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
