// Copyright 2018-2021 System76
// SPDX-License-Identifier: GPL-3.0-or-later



public class RefreshNotFoundView: OptionsView {
    public signal void next_step();
    public signal void choose_another();

    private Gtk.Button choose_another_button;

    public RefreshNotFoundView () {
        Object (
            cancellable: true,
            artwork: "try-install",
            title: _("Install")
        );
    }

    construct {
        cancel_button.label = _("Back");
        next_button.label = _("Continue to Clean Install");
        next.connect (() => next_step ());

        choose_another_button = new Gtk.Button.with_label(_("Select Another Partition"));
        choose_another_button.clicked.connect(() => this.choose_another());
        this.action_area.add(choose_another_button);

        show_all ();
    }

    public void can_choose_another(bool can) {
        if (can) {
            choose_another_button.show();
        } else {
            choose_another_button.hide();
        }
    }

    public void reset() {
        next_button.sensitive = false;

        base.clear_options();

        var description = new Gtk.Label(_("Pop!_OS was not found and Refresh Install is unavailable."));
        description.wrap = true;
        description.hexpand = true;
        description.max_width_chars = 60;
        description.margin_bottom = 8;

        base.options.add(description);

        string pretty_name = Utils.get_pretty_name ();

        base.add_option(
            "system-os-installer",
            _("Clean Install"),
            _("Erase everything and install a fresh copy of %s.").printf (pretty_name),
            (button) => {
                button.key_press_event.connect ((event) => handle_key_press (button, event));
                    button.notify["active"].connect (() => {
                        if (button.active) {
                            base.options.get_children ().foreach ((child) => {
                                ((Gtk.ToggleButton)child).active = child == button;
                            });

                            next_button.sensitive = true;
                            next_button.has_default = true;
                        } else {
                            next_button.sensitive = false;
                        }
                    });
            }
        );

        base.options.show_all ();
    }

    private bool handle_key_press (Gtk.Button button, Gdk.EventKey event) {
        if (event.keyval == Gdk.Key.Return) {
            button.clicked ();
            next_button.clicked ();
            return true;
        }

        return false;
    }
}