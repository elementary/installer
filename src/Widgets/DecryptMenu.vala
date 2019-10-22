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
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public delegate void DecryptFn (string path, string pv, string pass, Installer.DecryptMenu menu);

public class Installer.DecryptMenu: Gtk.Popover {
    private Gtk.Stack stack;

    private Gtk.Grid decrypt_view;
    private Gtk.Button decrypt_button;
    private Gtk.Entry pass_entry;
    private Gtk.Entry pv_entry;

    public DecryptMenu (string device_path, DecryptFn decrypt) {
        stack = new Gtk.Stack ();
        stack.margin = 12;
        create_decrypt_view (device_path, decrypt);
        add (stack);
        stack.show_all ();
    }

    private void create_decrypt_view (string device_path, DecryptFn decrypt) {
        var image = new Gtk.Image.from_icon_name ("drive-harddisk", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var overlay_image = new Gtk.Image.from_icon_name ("dialog-password", Gtk.IconSize.DND);
        overlay_image.halign = Gtk.Align.END;
        overlay_image.valign = Gtk.Align.END;

        var overlay = new Gtk.Overlay ();
        overlay.halign = Gtk.Align.CENTER;
        overlay.valign = Gtk.Align.END;
        overlay.width_request = 60;
        overlay.add (image);
        overlay.add_overlay (overlay_image);

        var primary_label = new Gtk.Label (_("Decrypt This Partition"));
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);
        primary_label.halign = Gtk.Align.START;

        var secondary_label = new Gtk.Label (_("Enter the partition's encryption password and set a device name for the decrypted partition."));
        secondary_label.halign = Gtk.Align.START;
        secondary_label.max_width_chars = 50;
        secondary_label.selectable = true;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var dialog_grid = new Gtk.Grid ();
        dialog_grid.column_spacing = 12;
        dialog_grid.attach (overlay, 0, 0, 1, 2);
        dialog_grid.attach (primary_label, 1, 0);
        dialog_grid.attach (secondary_label, 1, 1);

        var pass_label = new Gtk.Label (_("Password:"));
        pass_label.halign = Gtk.Align.END;

        pass_entry = new Gtk.Entry ();
        pass_entry.input_purpose = Gtk.InputPurpose.PASSWORD;
        pass_entry.visibility = false;
        pass_entry.changed.connect (() => set_sensitivity ());
        pass_entry.activate.connect (() => {
            if (entries_set ()) {
                decrypt (device_path, pv_entry.get_text (), pass_entry.get_text (), this);
            }
        });

        var pv_label = new Gtk.Label (_("Device name:"));
        pv_label.halign = Gtk.Align.END;

        pv_entry = new Gtk.Entry ();
        // Set a sane default
        pv_entry.text = "data";
        pv_entry.changed.connect (() => set_sensitivity ());
        pv_entry.activate.connect (() => {
            if (entries_set ()) {
                decrypt (device_path, pv_entry.get_text (), pass_entry.get_text (), this);
            }
        });

        decrypt_button = new Gtk.Button.with_label (_("Decrypt"));
        decrypt_button.halign = Gtk.Align.END;
        decrypt_button.sensitive = false;
        decrypt_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        decrypt_button.clicked.connect (() => {
            decrypt (device_path, pv_entry.get_text (), pass_entry.get_text (), this);
        });

        decrypt_view = new Gtk.Grid ();
        decrypt_view.column_spacing = 6;
        decrypt_view.row_spacing = 12;

        decrypt_view.attach (dialog_grid, 0, 0, 2);
        decrypt_view.attach (pass_label, 0, 1);
        decrypt_view.attach (pass_entry, 1, 1);
        decrypt_view.attach (pv_label, 0, 2);
        decrypt_view.attach (pv_entry, 1, 2);
        decrypt_view.attach (decrypt_button, 0, 3, 2);

        stack.add (decrypt_view);
        stack.visible_child = decrypt_view;
        pass_entry.grab_focus_without_selecting ();
    }

    private void create_decrypted_view (string pv) {
        var label = new Gtk.Label ("<b>%s</b>".printf (pv));
        label.use_markup = true;

        var info = new Gtk.Label (_("LUKS volume was decrypted"));

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        box.add (label);
        box.add (info);
        box.show_all ();

        stack.add (box);
        stack.visible_child = box;
    }

    private bool entries_set () {
        return pass_entry.get_text ().length != 0
            && pv_entry.get_text ().length != 0;
    }

    private void set_sensitivity () {
        decrypt_button.set_sensitive (entries_set ());
    }

    public void set_decrypted (string pv) {
        popdown ();
        create_decrypted_view (pv);
    }
}
