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

public class ProgressView : AbstractInstallerView {
    public signal void on_success ();
    public signal void on_error ();

    construct {
        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo-symbolic";
        logo.pixel_size = 128;

        var terminal_output = new Gtk.Frame (null);
        terminal_output.expand = true;

        var logo_stack = new Gtk.Stack ();
        logo_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        logo_stack.add (logo);
        logo_stack.add (terminal_output);

        var terminal_button = new Gtk.ToggleButton ();
        terminal_button.halign = Gtk.Align.END;
        terminal_button.image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        terminal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var progressbar_label = new Gtk.Label ("Partitioning drives");
        progressbar_label.xalign = 0;
        progressbar_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var progressbar = new Gtk.ProgressBar ();
        progressbar.hexpand = true;

        content_area.margin_end = 22;
        content_area.margin_start = 22;
        content_area.attach (logo_stack, 0, 0, 2, 1);
        content_area.attach (progressbar_label, 0, 1, 1, 1);
        content_area.attach (terminal_button, 1, 1, 1, 1);
        content_area.attach (progressbar, 0, 2, 2, 1);

        terminal_button.toggled.connect (() => {
            if (terminal_button.active) {
                logo_stack.visible_child = terminal_output;
            } else {
                logo_stack.visible_child = logo;
            }
        });

        Timeout.add_seconds (20, () => {
            if (terminal_button.active) {
                on_error ();
            } else {
                on_success ();
            }

            return GLib.Source.REMOVE;
        });

        show_all ();
    }
}
