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
    private ErrorRevealer confirm_entry_revealer;
    private ErrorRevealer pw_error_revealer;
    private Gtk.Button next_button;
    private Gtk.Button encrypt_button;
    private Granite.ValidatedEntry confirm_entry;
    private ValidatedEntry pw_entry;
    private Gtk.LevelBar pw_levelbar;

    private const string SKIP_STRING = _("Don’t Encrypt");

    public EncryptView () {
        Object (cancellable: true);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("drive-harddisk") {
            pixel_size = 128
        };

        var overlay_image = new Gtk.Image.from_icon_name ("security-high") {
            pixel_size = 64,
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        var overlay = new Gtk.Overlay () {
            child = image,
            halign = CENTER,
            width_request = 60
        };
        overlay.add_overlay (overlay_image);

        title = _("Enable Drive Encryption");

        var title_label = new Gtk.Label (title);

        var protect_row = new DescriptionRow (
            _("Data will only be protected from others with physical access to this device when it is shut down."),
            "security-high-symbolic",
            "green"
        );

        var restart_row = new DescriptionRow (
            _("The encryption password will be required each time this device is turned on. If you forget the encryption password, <b>you will not be able to recover data.</b>"),
            "system-reboot-symbolic",
            "blue"
        );

        var keyboard_row = new DescriptionRow (
            _("A built-in or USB keyboard will be required to type the encryption password each time this device is turned on."),
            "input-keyboard-symbolic",
            "slate"
        );

        var pw_label = new Granite.HeaderLabel (_("Choose Encryption Password")) {
            secondary_text = _("This is a unique password for this device, not the password for your user account.")
        };

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.label_widget.add_css_class (Granite.STYLE_CLASS_WARNING);

        pw_entry = new ValidatedEntry ();

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
        confirm_entry_revealer.label_widget.add_css_class (Granite.STYLE_CLASS_ERROR);

        var password_box = new Gtk.Box (VERTICAL, 3);
        password_box.append (pw_label);
        password_box.append (pw_entry);
        password_box.append (pw_levelbar);
        password_box.append (pw_error_revealer);
        password_box.append (confirm_label);
        password_box.append (confirm_entry);
        password_box.append (confirm_entry_revealer);

        title_area.append (overlay);
        title_area.append (title_label);

        content_area.valign = CENTER;
        content_area.append (protect_row);
        content_area.append (restart_row);
        content_area.append (keyboard_row);
        content_area.append (password_box);

        encrypt_button = new Gtk.Button.with_label (_("Set Password")) {
            sensitive = false
        };

        next_button = new Gtk.Button.with_label (_(SKIP_STRING)) {
            receives_default = true
        };
        next_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        action_box_end.append (encrypt_button);
        action_box_end.append (next_button);

        shown.connect (() => {
            ((Gtk.Window) get_root ()).default_widget = encrypt_button;
        });

        encrypt_button.clicked.connect (() => {
            Configuration.get_default ().encryption_password = pw_entry.text;
            next_step ();
        });

        next_button.clicked.connect (() => {
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
            encrypt_button.sensitive = true;
        } else {
            encrypt_button.sensitive = false;
        }
    }

    private class ValidatedEntry : Gtk.Entry {
        public bool is_valid { get; set; default = false; }

        construct {
            activates_default = true;
            visibility = false;
        }
    }

    private class ErrorRevealer : Gtk.Box {
        public bool reveal_child { get; set; }
        public Gtk.Label label_widget { get; private set; }
        public string label { get; construct set; }

        public ErrorRevealer (string label) {
            Object (label: label);
        }

        construct {
            label_widget = new Gtk.Label (label) {
                hexpand = true,
                justify = RIGHT,
                use_markup = true,
                wrap = true,
                xalign = 1
            };
            label_widget.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

            var revealer = new Gtk.Revealer () {
                child = label_widget,
                transition_type = CROSSFADE
            };

            append (revealer);

            bind_property ("reveal-child", revealer, "reveal-child");
            bind_property ("label", label_widget, "label");
        }
    }
}
