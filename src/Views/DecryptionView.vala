// Copyright 2018-2021 System76
// SPDX-License-Identifier: GPL-3.0-or-later

public class Installer.DecryptionView : AbstractInstallerView {
    public signal void decrypt (string key);

    private Gtk.Label err_label;
    private Gtk.Entry pw_entry;

    construct {
        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("disks");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var label = new Gtk.Label (_("Decrypt Install"));
        label.max_width_chars = 60;
        label.valign = Gtk.Align.START;
        label.get_style_context ().add_class ("h2");

        var desc_label = new Gtk.Label (_("Enter the password to decrypt the existing install."));
        desc_label.hexpand = true;
        desc_label.max_width_chars = 60;
        desc_label.wrap = true;
        desc_label.get_style_context ().add_class ("h3");

        this.err_label = new Gtk.Label (null);
        this.err_label.hexpand = true;
        this.err_label.max_width_chars = 60;
        this.err_label.wrap = true;
        this.err_label.set_no_show_all(true);
        this.err_label.hide();

        pw_entry = new Gtk.Entry ();
        pw_entry.visibility = false;
        pw_entry.grab_focus ();

        var pw_button = new Gtk.Button.with_label(_("Decrypt"));
        pw_button.sensitive = false;

        pw_entry.activate.connect (() => pw_button.clicked ());
        pw_entry.changed.connect (() => {
            pw_button.sensitive = pw_entry.text_length != 0;
        });

        pw_button.clicked.connect (() => {
            pw_button.sensitive = false;
            decrypt (pw_entry.text);
            pw_entry.text = "";
        });

        var right_pane = new Gtk.Grid ();
        right_pane.halign = Gtk.Align.CENTER;
        right_pane.valign = Gtk.Align.CENTER;
        right_pane.orientation = Gtk.Orientation.VERTICAL;
        right_pane.vexpand = true;
        right_pane.row_spacing = 24;
        right_pane.add (desc_label);
        right_pane.add (pw_entry);
        right_pane.add (this.err_label);

        content_area.attach (artwork, 0, 0, 1, 1);
        content_area.attach (label, 0, 1, 1, 1);
        content_area.attach (right_pane, 1, 0, 1, 2);

        action_area.add (pw_button);
        show_all ();
    }

    public void failed(string why) {
        this.err_label.set_text(@"Decryption failed: $why");
        this.err_label.show();
    }

    public void reset() {
        this.err_label.hide();
        pw_entry.text = "";
    }

}
