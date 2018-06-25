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

    public string log { get; construct; }

    public SuccessView (string log) {
        Object (log: log);
    }

    construct {
        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("success");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var title_label = new Gtk.Label (_("Continue Setting Up"));
        title_label.halign = Gtk.Align.CENTER;
        title_label.max_width_chars = 30;
        title_label.valign = Gtk.Align.START;
        title_label.wrap = true;
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("h2");

        var description_label = new Gtk.Label (_("After restarting you can set up a new user, or you can shut down now and set up a new user later."));
        description_label.max_width_chars = 52;
        description_label.wrap = true;
        description_label.xalign = 0;
        description_label.use_markup = true;

        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.margin_left = 24;
        grid.valign = Gtk.Align.CENTER;
        grid.attach (description_label, 0, 0, 1, 1);

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
        label_area.halign = Gtk.Align.FILL;
        label_area.valign = Gtk.Align.FILL;
        label_area.attach (artwork,       0, 0, 1, 1);
        label_area.attach (title_label, 0, 1, 1, 1);
        label_area.attach (grid,        1, 0, 1, 2);

        var content_stack = new Gtk.Stack ();
        content_stack.add (label_area);
        content_stack.add (terminal_output);
        content_area.attach (content_stack, 0, 0, 1, 1);

        var terminal_button = new Gtk.ToggleButton ();
        terminal_button.halign = Gtk.Align.END;
        terminal_button.image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        terminal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        terminal_button.toggled.connect (() => {
            if (terminal_button.active) {
                content_stack.visible_child = terminal_output;
            } else {
                content_stack.visible_child = label_area;
            }
        });
        action_area.add (terminal_button);

        var shutdown_button = new Gtk.Button.with_label (_("Shut Down"));
        shutdown_button.clicked.connect (Utils.shutdown);

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));
        restart_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        restart_button.clicked.connect (Utils.restart);

        action_area.add (shutdown_button);
        action_area.add (restart_button);

        show_all ();
    }
}
