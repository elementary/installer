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
    construct {
        var image = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (_("Could not install %s").printf (Utils.get_pretty_name ()));
        primary_label.max_width_chars = 60;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class ("h2");

        var secondary_label = new Gtk.Label (_("The installation failed, so your device may not restart properly. You can try one of the following:
• Try the installation again
• Launch a session and try to manually recover
• Restart your device to boot from another drive"));
        secondary_label.max_width_chars = 60;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;
        secondary_label.use_markup = true;

        content_area.halign = Gtk.Align.CENTER;
        content_area.valign = Gtk.Align.CENTER;
        content_area.margin_end = 22;
        content_area.margin_start = 22;
        content_area.row_spacing = 6;
        content_area.attach (image, 0, 0, 1, 2);
        content_area.attach (primary_label, 1, 0, 1, 1);
        content_area.attach (secondary_label, 1, 1, 1, 1);

        var restart_button = new Gtk.Button.with_label (_("Restart Device"));

        var session_button = new Gtk.Button.with_label (_("Launch Session"));

        var install_button = new Gtk.Button.with_label (_("Try Installing Again"));
        install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (restart_button);
        action_area.add (session_button);
        action_area.add (install_button);
    }
}

