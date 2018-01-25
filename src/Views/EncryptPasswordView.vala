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

public class EncryptPasswordView : AbstractInstallerView {
    public signal void next_step ();

    private ErrorRevealer confirm_entry_revealer;
    private ErrorRevealer pw_error_revealer;
    private Gtk.Button next_button;
    private ValidatedEntry confirm_entry;
    private ValidatedEntry pw_entry;
    private Gtk.LevelBar pw_levelbar;

    construct {
        var image = new Gtk.Image.from_icon_name ("dialog-password", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Encryption Password"));
        title_label.get_style_context ().add_class ("h2");
        title_label.valign = Gtk.Align.START;

        var description = new Gtk.Label (_("If you forget the encryption password, <b>you will not be able to recover data.</b> This is a unique password for this device, not the password for your user account."));
        description.margin_bottom = 12;
        description.max_width_chars = 60;
        description.use_markup = true;
        description.wrap = true;
        description.xalign = 0;

        var pw_label = new Granite.HeaderLabel (_("Choose Encryption Password"));

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);

        pw_entry = new ValidatedEntry ();
        pw_entry.visibility = false;

        pw_levelbar = new Gtk.LevelBar ();
        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 50.0);
        pw_levelbar.add_offset_value ("high", 75.0);
        pw_levelbar.add_offset_value ("middle", 75.0);

        var confirm_label = new Granite.HeaderLabel (_("Confirm Password"));

        confirm_entry = new ValidatedEntry ();
        confirm_entry.sensitive = false;
        confirm_entry.visibility = false;

        confirm_entry_revealer = new ErrorRevealer (".");
        confirm_entry_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        var password_grid = new Gtk.Grid ();
        password_grid.orientation = Gtk.Orientation.VERTICAL;
        password_grid.row_spacing = 3;
        password_grid.valign = Gtk.Align.CENTER;
        password_grid.vexpand = true;
        password_grid.add (description);
        password_grid.add (pw_label);
        password_grid.add (pw_entry);
        password_grid.add (pw_levelbar);
        password_grid.add (pw_error_revealer);
        password_grid.add (confirm_label);
        password_grid.add (confirm_entry);
        password_grid.add (confirm_entry_revealer);

        content_area.column_homogeneous = true;
        content_area.margin_end = 12;
        content_area.margin_start = 12;
        content_area.attach (image, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (password_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        next_button = new Gtk.Button.with_label (_("Select Disk"));
        next_button.sensitive = false;
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (next_button);

        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        pw_entry.changed.connect (() => {
            pw_entry.is_valid = check_password ();
            confirm_entry.is_valid = confirm_password ();
            update_next_button ();
        });

        confirm_entry.changed.connect (() => {
            confirm_entry.is_valid = confirm_password ();
            update_next_button ();
        });

        show_all ();
    }

    private bool check_password () {
        if (pw_entry.text == "") {
            confirm_entry.text = "";
            confirm_entry.sensitive = false;

            pw_levelbar.value = 0;

            pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            pw_error_revealer.reveal_child = false;
        } else {
            confirm_entry.sensitive = true;

            var pwquality = new PasswordQuality.Settings ();
            void* error;
            var quality = pwquality.check (pw_entry.text, null, null, out error);

            if (quality >= 0) {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                pw_error_revealer.reveal_child = false;

                pw_levelbar.value = quality;
            } else {
                pw_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");

                pw_error_revealer.reveal_child = true;
                pw_error_revealer.label = ((PasswordQuality.Error) quality).to_string (error);

                pw_levelbar.value = 0;
            }
            return true;
        }

        return false;
    }

    private bool confirm_password () {
        if (confirm_entry.text != "") {
            if (pw_entry.text != confirm_entry.text) {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error-symbolic");
                confirm_entry_revealer.label = _("Passwords do not match");
                confirm_entry_revealer.reveal_child = true;
            } else {
                confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-completed-symbolic");
                confirm_entry_revealer.reveal_child = false;
                return true;
            }
        } else {
            confirm_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            confirm_entry_revealer.reveal_child = false;
        }

        return false;
    }

    private void update_next_button () {
        if (pw_entry.is_valid && confirm_entry.is_valid) {
            next_button.sensitive = true;
        } else {
            next_button.sensitive = false;
        }
    }

    private class ValidatedEntry : Gtk.Entry {
        public bool is_valid { get; set; default = false; }
    }

    private class ErrorRevealer : Gtk.Revealer {
        public Gtk.Label label_widget;

        public string label {
            set {
                label_widget.label = "<span font_size=\"small\">%s</span>".printf (value);
            }
        }

        public ErrorRevealer (string label) {
            label_widget = new Gtk.Label ("<span font_size=\"small\">%s</span>".printf (label));
            label_widget.halign = Gtk.Align.END;
            label_widget.justify = Gtk.Justification.RIGHT;
            label_widget.max_width_chars = 55;
            label_widget.use_markup = true;
            label_widget.wrap = true;
            label_widget.xalign = 1;

            transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            add (label_widget);
        }
    }
}
