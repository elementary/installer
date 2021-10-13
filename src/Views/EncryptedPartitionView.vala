// Copyright 2021 System76
// SPDX-License-Identifier: GPL-3.0-or-later

public class EncryptedPartitionView: OptionsView {
    public signal void decrypt(string uuid);

    private string? selected_uuid = null;

    public EncryptedPartitionView() {
        Object (
            cancellable: false,
            artwork: "disks",
            title: _("Select Encrypted Partition")
        );
    }

    construct {
        this.next_button.label = _("Select");
        this.next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        this.next.connect(() => {
            if (this.selected_uuid != null) {
                this.decrypt(this.selected_uuid);
            }
        });

        this.show_all();
    }

    public void clear() {
        base.clear_options();
    }

    public new void add_option(EncryptedDevice device) {
        base.add_option(
            "drive-harddisk",
            device.device.path,
            null,
            (button) => {
                button.key_press_event.connect((event) => handle_key_press(button, event));
                button.notify["active"].connect(() => {
                    this.next_button.sensitive = button.active;
                    if (button.active) {
                        this.selected_uuid = device.uuid;
                    } else if (this.selected_uuid == device.uuid) {
                        this.selected_uuid = null;
                    }
                });
            }
        );
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