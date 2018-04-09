// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016-2018 elementary LLC. (https://elementary.io)
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
    private Gtk.Stack container;

    private Gtk.Container decrypt_view;
    private Gtk.Button decrypt_button;
    private Gtk.Entry pass_entry;
    private Gtk.Entry pv_entry;

    public DecryptMenu (string device_path, DecryptFn decrypt) {
        container = new Gtk.Stack ();
        container.margin = 12;
        create_decrypt_view (device_path, decrypt);
        add (container);
        container.show_all ();
    }

    private void create_decrypt_view (string device_path, DecryptFn decrypt) {
        pass_entry = new Gtk.Entry ();
        pass_entry.placeholder_text = "Password";
        pass_entry.changed.connect (() => set_sensitivity ());
        pass_entry.activate.connect (() => {
            if (entries_set ()) {
                decrypt (device_path, pv_entry.get_text (), pass_entry.get_text (), this);
            }
        });

        pv_entry = new Gtk.Entry ();
        pv_entry.placeholder_text = "Physical Volume";
        pv_entry.changed.connect (() => set_sensitivity ());
        pv_entry.activate.connect (() => {
            if (entries_set ()) {
                decrypt (device_path, pv_entry.get_text (), pass_entry.get_text (), this);
            }
        });

        decrypt_button = new Gtk.Button.with_label (_("Decrypt"));
        decrypt_button.clicked.connect (() => {
            decrypt (device_path, pv_entry.get_text (), pass_entry.get_text (), this);
        });



        decrypt_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        decrypt_view.add(pass_entry);
        decrypt_view.add(pv_entry);
        decrypt_view.add(decrypt_button);

        container.add (decrypt_view);
        container.set_visible_child (decrypt_view);
    }

    private void create_decrypted_view (string pv) {
        var label = new Gtk.Label ("<b>%s</b>".printf (pv));
        label.use_markup = true;

        var info = new Gtk.Label (_("LUKS volume was decrypted"));

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        box.add (label);
        box.add (info);
        box.show_all ();

        container.add (box);
        container.set_visible_child (box);
    }

    private bool entries_set () {
        return pass_entry.get_text ().length != 0
            && pv_entry.get_text ().length != 0;
    }

    private void set_sensitivity () {
        decrypt_button.set_sensitive(entries_set ());
    }

    public void set_decrypted (string pv) {
        popdown();
        create_decrypted_view (pv);
    }
}
