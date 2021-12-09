// Copyright 2021 System76
// SPDX-License-Identifier: GPL-3.0-or-later

public class EncryptedPartitionView: OptionsView {
    public signal void decrypt(string uuid);
    public signal void refresh();

    private string? selected_uuid = null;
    private bool os_selected = false;

    public EncryptedPartitionView() {
        Object (
            cancellable: true,
            artwork: "disks",
            title: _("Select OS or Encrypted Partition")
        );
    }

    construct {
        this.cancel_button.set_label(_("Back"));

        this.next_button.label = _("Select");
        this.next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        this.next.connect(() => {
            if (this.os_selected) {
                this.refresh();
                return;
            }

            if (this.selected_uuid != null) {
                this.decrypt(this.selected_uuid);
            }
        });

        this.show_all();
    }

    public void clear() {
        base.clear_options();
    }

    public new void select_first_option() {
        base.select_first_option();
    }

    public new void add_option(EncryptedDevice device) {
        base.add_option(
            "drive-harddisk",
            device.device.path,
            null,
            (button) => {
                button.key_press_event.connect((event) => handle_key_press(button, event));
                button.notify["active"].connect(() => {
                    if (button.active) {
                        base.options.get_children ().foreach ((child) => {
                            ((Gtk.ToggleButton)child).active = child == button;
                        });
                        this.selected_uuid = device.uuid;
                        this.os_selected = false;
                    } else if (this.selected_uuid == device.uuid) {
                        this.selected_uuid = null;
                    }

                    this.next_button.sensitive = button.active;
                });
            }
        );
    }

    public void add_refresh_installs() {
        var install_options = InstallOptions.get_default ();
        var uuids = new Gee.ArrayList<string>();

        unowned Distinst.InstallOptions updated = install_options.get_updated_options ();
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

                            this.os_selected = true;
                            this.selected_uuid = null;
                            next_button.sensitive = true;
                            next_button.has_default = true;
                        } else {
                            next_button.sensitive = false;
                        }
                    });
                }
            );
        }
    }

    private bool handle_key_press(Gtk.Button button, Gdk.EventKey event) {
        if (event.keyval == Gdk.Key.Return) {
            button.clicked();
            next_button.clicked();
            return true;
        }

        return false;
    }
}