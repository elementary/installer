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

    private Gtk.Button next_button;
    private Gtk.RadioButton encrypt_radio;
    private Gtk.RadioButton no_encrypt_radio;

    construct {
        var image = new Gtk.Image.from_icon_name ("drive-harddisk", Gtk.IconSize.DIALOG);

        var overlay_image = new Gtk.Image.from_icon_name ("locked", Gtk.IconSize.LARGE_TOOLBAR);
        overlay_image.halign = Gtk.Align.END;
        overlay_image.valign = Gtk.Align.END;

        var overlay = new Gtk.Overlay ();
        overlay.halign = Gtk.Align.CENTER;
        overlay.valign = Gtk.Align.END;
        overlay.width_request = 60;
        overlay.add (image);
        overlay.add_overlay (overlay_image);

        var title_label = new Gtk.Label (_("Encryption"));
        title_label.get_style_context ().add_class ("h2");
        title_label.valign = Gtk.Align.START;

        var choice_description = new Gtk.Label (_("Much secure. Your workplace might require encryption. Words. Lorem ipsum dolor sit amet."));
        choice_description.margin_bottom = 12;
        choice_description.max_width_chars = 60;
        choice_description.wrap = true;
        choice_description.xalign = 0;

        var default_button = new Gtk.RadioButton (null);

        encrypt_radio = new Gtk.RadioButton.with_label_from_widget (default_button, _("Encrypt"));

        no_encrypt_radio = new Gtk.RadioButton.with_label_from_widget (default_button, _("Don't Encrypt"));

        var choice_grid = new Gtk.Grid ();
        choice_grid.orientation = Gtk.Orientation.VERTICAL;
        choice_grid.row_spacing = 12;
        choice_grid.valign = Gtk.Align.CENTER;
        choice_grid.vexpand = true;
        choice_grid.add (choice_description);
        choice_grid.add (encrypt_radio);
        choice_grid.add (no_encrypt_radio);

        content_area.column_homogeneous = true;
        content_area.margin_end = 12;
        content_area.margin_start = 12;
        content_area.attach (overlay, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (choice_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        next_button = new Gtk.Button.with_label (_("Don't Encrypt"));
        next_button.sensitive = false;

        action_area.add (back_button);
        action_area.add (next_button);

        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        encrypt_radio.toggled.connect (radio_toggled);
        no_encrypt_radio.toggled.connect (radio_toggled);

        show_all ();
    }

    private void radio_toggled () {
        if (encrypt_radio.active) {
            next_button.label = _("Choose Password");
        } else if (no_encrypt_radio.active) {
            next_button.label = _("Don't Encrypt");
        }

        next_button.clicked.connect (() => next_step ());
        next_button.sensitive = true;
    }
}
