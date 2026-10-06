/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Installer.ChoiceView : AbstractInstallerView {
    public InstallerDaemon.Backend choice { get; private set; default = InstallerDaemon.Backend.UNKNOWN; }

    construct {
        var type_image = new Gtk.Image.from_icon_name ("dialog-question") {
            pixel_size = 128
        };

        title = _("Choose Install Mode");

        var type_label = new Gtk.Label (title);

        // Force the user to make a conscious selection, not spam "Next"
        var no_selection = new Gtk.CheckButton () {
            active = true
        };

        var type_box = new Gtk.Box (VERTICAL, 6) {
            valign = CENTER,
            vexpand = true
        };

        var back_button = new Gtk.Button.with_label (_("Back")) {
            action_name = "win.back"
        };

        var next_button = new Gtk.Button.with_label (_("Next")) {
            sensitive = false
        };
        next_button.add_css_class (Granite.CssClass.SUGGESTED);

        action_box_end.append (back_button);
        action_box_end.append (next_button);

        next_button.clicked.connect (() => {
                try {
                    if (!Installer.App.test_mode) {
                        Daemon.get_default ().set_backend (choice);
                    }
                    info ("Set backend to: %s", choice.to_string ());
                } catch (GLib.Error e) {
                    critical ("Could not set backend to %s", e.message);
                    sensitive = false;
                    return;
                }

                next_step ();
        });

        foreach (var backend in get_backends ()) {
            var backend_button = new InstallTypeButton (
                backend.get_title (),
                backend == REPART ? "security-high" : "security-low",
                backend.get_description ()
            ) {
                group = no_selection
            };

            backend_button.toggled.connect (() => {
                if (backend_button.active) {
                    choice = backend;
                    next_button.sensitive = true;
                }
            });

            type_box.append (backend_button);
        }

        var type_scrolled = new Gtk.ScrolledWindow () {
            child = type_box,
            hscrollbar_policy = NEVER,
            propagate_natural_height = true
        };

        title_area.append (type_image);
        title_area.append (type_label);

        content_area.append (type_scrolled);
    }
}
