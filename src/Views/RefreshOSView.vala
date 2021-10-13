// Copyright 2018-2021 System76
// SPDX-License-Identifier: GPL-3.0-or-later



public class RefreshOSView: OptionsView {
    public signal void next_step ();
    public signal void choose_another();

    public RefreshOSView () {
        Object (
            cancellable: true,
            artwork: "disks",
            title: _("Refresh Install")
        );
    }

    construct {
        next_button.label = _("Refresh Install");
        next.connect (() => {
            next_step ();
        });
        show_all ();
    }

    public int update_options () {
        int appended = 0;
        base.clear_options ();
        var install_options = InstallOptions.get_default ();
        unowned Distinst.Disks disks = install_options.borrow_disks ();
        foreach (var option in install_options.get_updated_options ().get_refresh_options ()) {
            var os = Utils.string_from_utf8 (option.get_os_name ());
            var version = Utils.string_from_utf8 (option.get_os_version ());
            var uuid = Utils.string_from_utf8 (option.get_root_part ());
            Distinst.OsRelease release;
            string? override_logo = null;
            if (option.get_os_release (out release) != 0) {
                override_logo = "tux";
            }

            unowned Distinst.Partition? partition = disks.get_partition_by_uuid (uuid);
            if (partition == null) {
                stderr.printf ("did not find partition with UUID \"%s\"\n", uuid);
                continue;
            }

            appended += 1;

            var device_path = Utils.string_from_utf8 (partition.get_device_path ());

            stderr.printf("Adding option for %s %s on %s\n", os, version, device_path);

            base.add_option (
                (override_logo == null) ? Utils.get_distribution_logo (release) : override_logo,
                _("%s (%s) at %s").printf (os, version, device_path),
                null,
                (button) => {
                    button.key_press_event.connect ((event) => handle_key_press (button, event));
                    button.notify["active"].connect (() => {
                        if (button.active) {
                            base.options.get_children ().foreach ((child) => {
                                ((Gtk.ToggleButton)child).active = child == button;
                            });

                            install_options.selected_option = new Distinst.InstallOption () {
                                tag = Distinst.InstallOptionVariant.REFRESH,
                                option = (void*) option,
                                encrypt_pass = null
                            };

                            next_button.sensitive = true;
                            next_button.has_default = true;
                        } else {
                            next_button.sensitive = false;
                        }
                    });
                }
            );
        }

        var choose_another_button = new Gtk.Button.with_label(_("Select Another Partition"));
        choose_another_button.clicked.connect(() => this.choose_another());
        choose_another_button.set_no_show_all(true);
        choose_another_button.hide();
        this.action_area.add(choose_another_button);

        this.next_button.get_style_context().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        base.options.show_all ();
        base.select_first_option ();
        return appended;
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