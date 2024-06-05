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

public class SuccessView : AbstractInstallerView {
    private const int RESTART_TIMEOUT = 30;
    private int seconds_remaining = RESTART_TIMEOUT;
    private Gtk.Label secondary_label;

    construct {
        var image = new Gtk.Image.from_icon_name ("process-completed", Gtk.IconSize.DIALOG) {
            pixel_size = 128
        };

        var title_label = new Gtk.Label (_("Continue Setting Up"));

        var primary_label = new Gtk.Label (_("%s has been installed").printf (Utils.get_pretty_name ())) {
            hexpand = true,
            max_width_chars = 1,
            wrap = true,
            xalign = 0
        };
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        secondary_label = new Gtk.Label (null) {
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            use_markup = true,
            wrap = true,
            xalign = 0
        };

        var message_grid = new Gtk.Grid () {
            row_spacing = 6,
            valign = CENTER,
            vexpand = true
        };
        message_grid.attach (primary_label, 0, 0);
        message_grid.attach (secondary_label, 0, 1);

        title_area.add (image);
        title_area.add (title_label);

        content_area.add (message_grid);

        var shutdown_button = new Gtk.Button.with_label (_("Shut Down"));
        shutdown_button.clicked.connect (Utils.shutdown);

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));
        restart_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        restart_button.clicked.connect (Utils.restart);

        action_box_end.add (shutdown_button);
        action_box_end.add (restart_button);

        update_secondary_label ();

        Timeout.add_seconds (RESTART_TIMEOUT, () => {
            Utils.restart ();
            return GLib.Source.REMOVE;
        });

        Timeout.add_seconds (1, () => {
            seconds_remaining = seconds_remaining - 1;
            update_secondary_label ();

            if (seconds_remaining == 0) {
                return Source.REMOVE;
            }

            return Source.CONTINUE;
        });

        show_all ();
    }

    private void update_secondary_label () {
        secondary_label.label = "<span font-features='tnum'>%s</span>".printf (
            ngettext (
                "Your device will automatically restart in %i second.",
                "Your device will automatically restart in %i seconds.",
                seconds_remaining
            ).printf (seconds_remaining) + " " +
            _("After restarting you can set up a new user, or you can shut down now and set up a new user later.")
        );
    }
}
