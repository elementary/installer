// Copyright 2018-2021 System76
// SPDX-License-Identifier: GPL-3.0-or-later



public class RefreshOSView: OptionsView {
    public signal void next_step ();

    public RefreshOSView () {
        Object (
            cancellable: true,
            artwork: "disks",
            title: _("Select OS or Encrypted Partition to Refresh")
        );
    }

    construct {
        next_button.label = _("Select");
        next.connect (() => {
            next_step ();
        });
        show_all ();
    }

    public void clear() {
        base.clear_options();
    }

    public int update_options () {
        int appended = 0;
        base.clear_options ();
        var install_options = InstallOptions.get_default ();
        var uuids = new Gee.ArrayList<string>();

        Gtk.Button? decrypted_os_button = null;

        unowned Distinst.InstallOptions updated = install_options.get_options ();
        unowned Distinst.Disks disks = install_options.borrow_disks ();
        foreach (var option in updated.get_refresh_options ()) {
            var os = Utils.string_from_utf8 (option.get_os_name ());
            var version = Utils.string_from_utf8 (option.get_os_version ());
            var uuid = Utils.string_from_utf8 (option.get_root_part ());

            if (uuids.contains(uuid)) continue;
            uuids.add(uuid);

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
                    if (decrypted_os_button == null && device_path.has_prefix("/dev/dm")) {
                        decrypted_os_button = button;
                    }

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

        this.next_button.get_style_context().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        base.options.show_all ();

        if (decrypted_os_button != null) {
            decrypted_os_button.grab_focus ();
            decrypted_os_button.clicked ();
        } else {
            base.select_first_option();
        }

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