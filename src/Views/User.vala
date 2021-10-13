public class UserView : AbstractInstallerView {
    public signal void next_step ();

    private ErrorRevealer confirm_entry_revealer;
    private ErrorRevealer pw_error_revealer;
    private Gtk.Button next_button;
    private Username username;
    private ValidatedEntry confirm_entry;
    private ValidatedEntry pw_entry;
    private Gtk.LevelBar pw_levelbar;

    public Gtk.Stack stack;
    public Gtk.Container password_section;
    public Gtk.Container user_section;

    public UserView() {
        Object(cancellable: true);
    }

    construct {
        cancel_button.label = _("Back");
        var user_icon = new IconChooser("/usr/share/pixmaps/faces/penguin.jpg") {
            halign = Gtk.Align.CENTER,
            hexpand = true
        };

        var artwork = new Gtk.Grid () { vexpand = true };
        artwork.get_style_context ().add_class ("create-account");
        artwork.get_style_context ().add_class ("artwork");

        var title_label = new Gtk.Label (_("Create User Account")) { valign = Gtk.Align.START };
        title_label.get_style_context ().add_class ("h2");

        username = new Username () {
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.CENTER
        };

        var pw_label = new Granite.HeaderLabel (_("Choose Account Password"));

        pw_entry = new ValidatedEntry () { visibility = false };

        pw_levelbar = new Gtk.LevelBar.for_interval (0.0, 100.0);
        pw_levelbar.set_mode (Gtk.LevelBarMode.CONTINUOUS);
        pw_levelbar.add_offset_value ("low", 50.0);
        pw_levelbar.add_offset_value ("high", 75.0);
        pw_levelbar.add_offset_value ("middle", 75.0);

        pw_error_revealer = new ErrorRevealer (".");
        pw_error_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_WARNING);

        var confirm_label = new Granite.HeaderLabel (_("Confirm Password"));

        confirm_entry = new ValidatedEntry () {
            sensitive = false,
            visibility = false
        };

        confirm_entry_revealer = new ErrorRevealer (".");
        confirm_entry_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        password_section = new Gtk.Box(Gtk.Orientation.VERTICAL, 3) { valign = Gtk.Align.CENTER };
        password_section.add (pw_label);
        password_section.add (pw_entry);
        password_section.add (pw_levelbar);
        password_section.add (pw_error_revealer);
        password_section.add (confirm_label);
        password_section.add (confirm_entry);
        password_section.add (confirm_entry_revealer);

        user_section = new Gtk.Box(Gtk.Orientation.VERTICAL, 3) { valign = Gtk.Align.CENTER };
        user_section.add (user_icon);
        user_section.add (username);

        stack = new Gtk.Stack();
        stack.add(user_section);
        stack.add(password_section);

        content_area.attach (artwork, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (stack, 1, 0, 1, 2);

        next_button = new Gtk.Button.with_label (_("Next")) {
            can_default = true,
            sensitive = true
        };

        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (next_button);

        next_button.clicked.connect (() => {
            if (stack.visible_child == user_section) {
                stack.visible_child = password_section;
                update_next_button();
                pw_entry.grab_focus();
                this.cancel_button.show();
                return;
            }
            var config = Configuration.get_default ();
            config.username = username.get_user_name ();
            config.realname = username.get_real_name ();
            config.password = pw_entry.get_text ();
            config.profile_icon = user_icon.icon_path;
            next_step ();
        });

        username.activate.connect (() => {
            if (username.is_ready ()) {
                next_button.clicked ();
            }
        });
        username.changed.connect (() => {
            update_next_button ();
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

        cancel.connect(() => {
            if (this.stack.visible_child != this.user_section) {
                this.stack.visible_child = this.user_section;
                this.update_next_button();
                this.reset_password();
                this.cancel_button.hide();
            }
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

    public void update_next_button() {
        bool enable;

        if (stack.visible_child == password_section) {
            enable = pw_entry.is_valid
                && confirm_entry.is_valid;
        } else {
            enable = username.is_ready();
        }

        if (enable) {
            next_button.sensitive = true;
            next_button.has_default = true;
        } else {
            next_button.sensitive = false;
        }
    }

    public void reset_password() {
        pw_entry.text = "";
        confirm_entry.text = "";
    }

    public new void grab_focus() {
        update_next_button ();
        username.grab_focus();
    }
}


