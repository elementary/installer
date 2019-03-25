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

public delegate bool DecryptFn (string path, string pv, string pass, Installer.DecryptMenu menu);

public class Installer.DecryptMenu: Gtk.Popover {
    private Gtk.Stack stack;
    private Gtk.Grid decrypt_view;
    private Gtk.Button decrypt_button;
    private Gtk.Entry pass_entry;
    private Gtk.Entry pv_entry;
    private PartitionBar partition_bar;
    private DecryptFn decrypt;
    private string device_path;

    public DecryptMenu (string device_path, DecryptFn decrypt, PartitionBar partition_bar) {
        this.partition_bar = partition_bar;
        this.decrypt = decrypt;
        this.device_path = device_path;
        stack = new Gtk.Stack ();
        stack.margin = 12;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        create_decrypt_view ();
        add (stack);
        stack.show_all ();
    }

    private void create_decrypt_view () {
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
        secondary_label.can_focus = false;

        var dialog_grid = new Gtk.Grid ();
        dialog_grid.column_spacing = 12;
        dialog_grid.attach (overlay,         0, 0, 1, 2);
        dialog_grid.attach (primary_label,   1, 0);
        dialog_grid.attach (secondary_label, 1, 1);

        var pass_label = new Gtk.Label (_("Password:"));
        pass_label.halign = Gtk.Align.END;

        pass_entry = new Gtk.Entry ();
        pass_entry.input_purpose = Gtk.InputPurpose.PASSWORD;
        pass_entry.visibility = false;
        pass_entry.has_focus = true;
        pass_entry.changed.connect (set_sensitivity);
        pass_entry.activate.connect (attempt_decrypt);

        var pv_label = new Gtk.Label (_("Device name:"));
        pv_label.halign = Gtk.Align.END;

        pv_entry = new Gtk.Entry ();
        pv_entry.text = "cryptdata";

        pv_entry.changed.connect (set_sensitivity);
        pv_entry.activate.connect (attempt_decrypt);

        decrypt_button = new Gtk.Button.with_label (_("Decrypt"));
        decrypt_button.halign = Gtk.Align.END;
        decrypt_button.sensitive = false;
        decrypt_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        decrypt_button.clicked.connect (attempt_decrypt);

        decrypt_view = new Gtk.Grid ();
        decrypt_view.column_spacing = 6;
        decrypt_view.row_spacing = 12;

        decrypt_view.attach (dialog_grid,    0, 0, 2);
        decrypt_view.attach (pass_label,     0, 1);
        decrypt_view.attach (pass_entry,     1, 1);
        decrypt_view.attach (pv_label,       0, 2);
        decrypt_view.attach (pv_entry,       1, 2);
        decrypt_view.attach (decrypt_button, 0, 3, 2);

        stack.add (decrypt_view);
        stack.visible_child = decrypt_view;
        pass_entry.grab_focus_without_selecting ();

        // Update the default LUKS PV name, to prevent namespace conflicts.
        this.notify["active"].connect (() => {
            string? pv_uid = Distinst.generate_unique_id("cryptdata");
            pv_entry.text = pv_uid != null ? pv_uid : "";
        });

        this.closed.connect (() => {
            stack.visible_child = decrypt_view;
        });
    }

    private void attempt_decrypt() {
        if (entries_set ()) {
            if (decrypt (device_path, pv_entry.get_text (), pass_entry.get_text (), this)) {
                var mount_icon = new Gtk.Image.from_icon_name (
                    "emblem-unlocked",
                    Gtk.IconSize.SMALL_TOOLBAR
                );
                mount_icon.halign = Gtk.Align.END;
                mount_icon.valign = Gtk.Align.END;
                mount_icon.margin = 6;

                partition_bar.container.pack_start (mount_icon, true, true, 0);
                partition_bar.container.show_all ();
                this.destroy ();
            }
        }
    }

    private bool entries_set () {
        return pass_entry.text_length != 0
            && pv_entry.text_length != 0;
    }

    private void set_sensitivity () {
        decrypt_button.set_sensitive (entries_set ());
    }

    public void set_error (string message) {
        var image = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;
        image.width_request = 60;

        var primary_label = new Gtk.Label ("Decryption Error");
        primary_label.halign = Gtk.Align.START;
        primary_label.valign = Gtk.Align.END;
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var secondary_label = new Gtk.Label (message);
        secondary_label.expand = true;
        secondary_label.max_width_chars = 40;
        secondary_label.valign = Gtk.Align.START;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var button = new Gtk.Button.with_label (_("Try Again"));
        button.halign = Gtk.Align.END;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.attach (image,           0, 0, 1, 2);
        grid.attach (primary_label,   1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (button,          1, 2);
        grid.show_all ();

        stack.add (grid);
        stack.visible_child = grid;

        button.has_focus = true;

        button.clicked.connect (() => {
            stack.visible_child = decrypt_view;
            grid.destroy ();
            pass_entry.has_focus = true;
        });
    }
}
