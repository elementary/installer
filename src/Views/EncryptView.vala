// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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

public class EncryptView : AbstractInstallerView {
    public signal void next_step ();

    construct {
        var image = new Gtk.Image.from_icon_name ("drive-harddisk", Gtk.IconSize.DIALOG);

        var overlay_image = new Gtk.Image.from_icon_name ("locked", Gtk.IconSize.DND);
        overlay_image.halign = Gtk.Align.END;
        overlay_image.valign = Gtk.Align.END;

        var overlay = new Gtk.Overlay ();
        overlay.halign = Gtk.Align.CENTER;
        overlay.valign = Gtk.Align.END;
        overlay.width_request = 60;
        overlay.add (image);
        overlay.add_overlay (overlay_image);

        var title_label = new Gtk.Label (_("Disk Encryption"));
        title_label.get_style_context ().add_class ("h2");
        title_label.valign = Gtk.Align.START;

        var choice_description = new Gtk.Label (_("Encrypting this disk protects data from being read by others with physical access to this device."));
        choice_description.max_width_chars = 60;
        choice_description.wrap = true;
        choice_description.xalign = 0;

        var choice_description2 = new Gtk.Label (_("The encryption password will be required each time you turn on this device or restart."));
        choice_description2.max_width_chars = 60;
        choice_description2.wrap = true;
        choice_description2.xalign = 0;

        var choice_description3 = new Gtk.Label (_("Disk encryption may minimally impact read and write speed when performing intense tasks."));
        choice_description3.max_width_chars = 60;
        choice_description3.wrap = true;
        choice_description3.xalign = 0;

        var choice_grid = new Gtk.Grid ();
        choice_grid.orientation = Gtk.Orientation.VERTICAL;
        choice_grid.column_spacing = 12;
        choice_grid.row_spacing = 32;
        choice_grid.valign = Gtk.Align.CENTER;
        choice_grid.vexpand = true;
        choice_grid.attach (new Gtk.Image.from_icon_name ("emoji-body-symbolic", Gtk.IconSize.LARGE_TOOLBAR), 0, 0, 1, 1);
        choice_grid.attach (choice_description, 1, 0, 1, 1);
        choice_grid.attach (new Gtk.Image.from_icon_name ("rotation-allowed-symbolic", Gtk.IconSize.LARGE_TOOLBAR), 0, 1, 1, 1);
        choice_grid.attach (choice_description2, 1, 1, 1, 1);
        choice_grid.attach (new Gtk.Image.from_icon_name ("emoji-objects-symbolic", Gtk.IconSize.LARGE_TOOLBAR), 0, 2, 1, 1);
        choice_grid.attach (choice_description3, 1, 2, 1, 1);

        content_area.column_homogeneous = true;
        content_area.margin_end = 12;
        content_area.margin_start = 12;
        content_area.attach (overlay, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (choice_grid, 1, 0, 1, 2);

        var no_encrypt_button = new Gtk.Button.with_label (_("Don't Encrypt"));

        var back_button = new Gtk.Button.with_label (_("Back"));

        var next_button = new Gtk.Button.with_label (_("Choose Password"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (no_encrypt_button);
        action_area.add (back_button);
        action_area.add (next_button);

        next_button.grab_focus ();

        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        next_button.clicked.connect (() => next_step ());

        show_all ();
    }
}
