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
    public uint64 minimum_disk_size { get; construct; }
    public string log { get; construct; }

    public ErrorView (string log, uint64 minimum_disk_size) {
        Object (log: log, minimum_disk_size: minimum_disk_size);
    }

    construct {
        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("error");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var title_label = new Gtk.Label (_("Could Not Install"));
        title_label.halign = Gtk.Align.CENTER;
        title_label.max_width_chars = 30;
        title_label.valign = Gtk.Align.START;
        title_label.wrap = true;
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("h2");

        var description_label = new Gtk.Label (_("Installing %s failed, possibly due to a hardware error. Detailed logs were written to <b>/tmp/installer.log</b>. Your device may not restart properly. You can try the following:").printf (Utils.get_pretty_name ()));
        description_label.max_width_chars = 52;
        description_label.wrap = true;
        description_label.xalign = 0;
        description_label.use_markup = true;

        var try_label = new Gtk.Label (_("• Try the installation again"));
        try_label.max_width_chars = 52;
        try_label.wrap = true;
        try_label.xalign = 0;
        try_label.use_markup = true;

        var launch_label = new Gtk.Label (_("• Use Demo Mode and try to manually recover"));
        launch_label.max_width_chars = 52;
        launch_label.wrap = true;
        launch_label.xalign = 0;
        launch_label.use_markup = true;

        var restart_label = new Gtk.Label (_("• Restart your device to boot from another drive"));
        restart_label.max_width_chars = 52;
        restart_label.wrap = true;
        restart_label.xalign = 0;
        restart_label.use_markup = true;

        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.margin_left = 24;
        grid.valign = Gtk.Align.CENTER;
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
        terminal_output.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        terminal_output.propagate_natural_width = true;
        terminal_output.add (terminal_view);
        terminal_output.vexpand = true;
        terminal_output.hexpand = true;

        var label_area = new Gtk.Grid ();
        label_area.column_homogeneous = true;
        label_area.halign = Gtk.Align.CENTER;
        label_area.valign = Gtk.Align.FILL;
        label_area.attach (artwork,       0, 0, 1, 1);
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

        restart_button.clicked.connect (Utils.restart);

        demo_button.clicked.connect (Utils.demo_mode);

        install_button.clicked.connect (() => {
            // This object is moved during install, so this will restore the default settings.
            var options = InstallOptions.get_default ();
            options.set_minimum_size (minimum_disk_size);
            options.get_options ();

            ((Gtk.Stack) get_parent ()).visible_child = previous_view;
        });

        show_all ();
    }
}
