/*
 * Copyright 2018–2021 elementary, Inc. (https://elementary.io)
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

    private ErrorRevealer confirm_entry_revealer;
    private ErrorRevealer pw_error_revealer;
    private Gtk.Button next_button;
    private Granite.ValidatedEntry confirm_entry;
    private ValidatedEntry pw_entry;
    private Gtk.LevelBar pw_levelbar;

    private const string SKIP_STRING = _("Don’t Encrypt");

    public EncryptView () {
        Object (cancellable: false);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("drive-harddisk", Gtk.IconSize.INVALID) {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        var overlay_image = new Gtk.Image.from_icon_name ("security-high", Gtk.IconSize.INVALID) {
            pixel_size = 64,
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        var overlay = new Gtk.Overlay () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.END,
            width_request = 60
        };
        overlay.add (image);
        overlay.add_overlay (overlay_image);

        var title_label = new Gtk.Label (_("Enable Drive Encryption")) {
            valign = Gtk.Align.START
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var details_label = new Gtk.Label (_("Encrypt this device's drive if required for added protection, but be sure you understand:")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };
        details_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var protect_image = new Gtk.Image.from_icon_name ("security-high-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        var protect_label = new Gtk.Label (_("Data will only be protected from others with physical access to this device when it is shut down.")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var restart_image = new Gtk.Image.from_icon_name ("system-reboot-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        var restart_label = new Gtk.Label (_("The encryption password will be required each time this device is turned on. Store it somewhere safe.")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var keyboard_image = new Gtk.Image.from_icon_name ("input-keyboard-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        var keyboard_label = new Gtk.Label (_("A built-in or USB keyboard will be required to type the encryption password each time this device is turned on.")) {
            hexpand = true,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            wrap = true,
            xalign = 0
        };

        var choice_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 32
        };
        choice_grid.attach (details_label, 0, 0, 2);
        choice_grid.attach (protect_image, 0, 1);
        choice_grid.attach (protect_label, 1, 1);
        choice_grid.attach (restart_image, 0, 2);
        choice_grid.attach (restart_label, 1, 2);
        choice_grid.attach (keyboard_image, 0, 3);
        choice_grid.attach (keyboard_label, 1, 3);

        var description = new Gtk.Label (
            _("If you forget the encryption password, <b>you will not be able to recover data.</b> This is a unique password for this device, not the password for your user account.")
        ) {
            hexpand = true,
            margin_bottom = 12,
            max_width_chars = 1, // Make Gtk wrap, but not expand the window
            use_markup = true,
            wrap = true,
            xalign = 0
        };

        var pw_label = new Granite.HeaderLabel (_("Choose Encryption Password"));

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);

        pw_entry = new ValidatedEntry ();
        pw_entry.visibility = false;

        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 50.0);
        pw_levelbar.add_offset_value ("high", 75.0);
        pw_levelbar.add_offset_value ("middle", 75.0);

        var confirm_label = new Granite.HeaderLabel (_("Confirm Password"));

        confirm_entry = new Granite.ValidatedEntry () {
            sensitive = false,
            visibility = false
        };

        confirm_entry_revealer = new ErrorRevealer (".");
        confirm_entry_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        var password_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            row_spacing = 3
        };
        password_grid.add (description);
        password_grid.add (pw_label);
        password_grid.add (pw_entry);
        password_grid.add (pw_levelbar);
        password_grid.add (pw_error_revealer);
        password_grid.add (confirm_label);
        password_grid.add (confirm_entry);
        password_grid.add (confirm_entry_revealer);

        var stack = new Gtk.Stack () {
            vhomogeneous = false,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        stack.add (choice_grid);
        stack.add (password_grid);

        content_area.column_homogeneous = true;
        content_area.margin_end = 12;
        content_area.margin_start = 12;
        content_area.attach (overlay, 0, 0);
        content_area.attach (title_label, 0, 1);
        content_area.attach (stack, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var encrypt_button = new Gtk.Button.with_label (_("Choose Password"));

        next_button = new Gtk.Button.with_label (_(SKIP_STRING)) {
            can_default = true
        };
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (encrypt_button);
        action_area.add (next_button);

        next_button.grab_focus ();

        back_button.clicked.connect (() => {
            stack.visible_child = choice_grid;
            next_button.label = _(SKIP_STRING);
            next_button.sensitive = true;
            back_button.hide ();
            encrypt_button.show ();
        });

        encrypt_button.clicked.connect (() => {
            stack.visible_child = password_grid;
            next_button.label = _("Set Encryption Password");
            update_next_button ();
            back_button.show ();
            encrypt_button.hide ();

            pw_entry.grab_focus ();
        });

        next_button.clicked.connect (() => {
            if (stack.visible_child == password_grid) {
                Configuration.get_default ().encryption_password = pw_entry.text;
            }

            next_step ();
        });

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
        back_button.hide ();
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
                confirm_entry_revealer.label = _("Passwords do not match");
                confirm_entry_revealer.reveal_child = true;
            } else {
                confirm_entry_revealer.reveal_child = false;
                return true;
            }
        } else {
            confirm_entry_revealer.reveal_child = false;
        }

        return false;
    }

    private void update_next_button () {
        if (pw_entry.is_valid && confirm_entry.is_valid) {
            next_button.sensitive = true;
            next_button.has_default = true;
        } else {
            next_button.sensitive = false;
        }
    }

    private class ValidatedEntry : Gtk.Entry {
        public bool is_valid { get; set; default = false; }

        construct {
            activates_default = true;
        }
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
