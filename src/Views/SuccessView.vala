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
        var image = new Gtk.Image.from_icon_name ("process-completed", Gtk.IconSize.DIALOG);
        image.vexpand = true;

        var primary_label = new Gtk.Label (_("Continue Setting Up"));
        primary_label.halign = Gtk.Align.START;
        primary_label.max_width_chars = 60;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var secondary_label = new Gtk.Label (
            _("Your device will automatically restart to %s in %i seconds.").printf (Utils.get_pretty_name (), RESTART_TIMEOUT) + " " +
            _("After restarting you can set up a new user, or you can shut down now and set up a new user later.")
        );
        secondary_label.max_width_chars = 60;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.margin_left = 24;
        grid.valign = Gtk.Align.CENTER;
        grid.attach (primary_label, 0, 0, 1, 1);
        grid.attach (secondary_label, 0, 1, 1, 1);

        var buffer = new Gtk.TextBuffer (null);
        buffer.text = log;
        var terminal = new Terminal (buffer);

        var label_area = new Gtk.Grid ();
        label_area.column_homogeneous = true;
        label_area.halign = Gtk.Align.FILL;
        label_area.valign = Gtk.Align.FILL;
        label_area.attach (image,       0, 0, 1, 1);
        label_area.attach (grid,        1, 0, 1, 2);

        var content_stack = new Gtk.Stack ();
        content_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        content_stack.add (label_area);
        content_stack.add (terminal.container);
        content_area.attach (content_stack, 0, 0, 1, 1);

        terminal.toggled.connect ((active) => {
            content_stack.visible_child = active
                ? (Gtk.Widget) terminal.container
                : (Gtk.Widget) label_area;
        });

        action_area.add (terminal.toggle);

        var shutdown_button = new Gtk.Button.with_label (_("Shut Down"));
        shutdown_button.clicked.connect (Utils.shutdown);

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));
        restart_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        restart_button.clicked.connect (Utils.restart);

        action_area.add (shutdown_button);
        action_area.add (restart_button);

        Timeout.add_seconds (RESTART_TIMEOUT, () => {
            Utils.restart ();
            return GLib.Source.REMOVE;
        });

        show_all ();
    }
}
