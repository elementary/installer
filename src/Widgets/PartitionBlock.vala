/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class Installer.PartitionBlock : Adw.Bin {
    public signal void decrypted (InstallerDaemon.LuksCredentials credential);

    public Icon? icon { get; set; default = null; }

    private Gtk.Popover _menu;
    public Gtk.Popover menu {
        get {
            return _menu;
        }

        set {
            _menu = value;
            _menu.set_parent (this);
            _menu.position = BOTTOM;

            var click_gesture = new Gtk.GestureClick ();
            click_gesture.released.connect (_menu.popup);

            add_controller (click_gesture);
        }
    }

    public InstallerDaemon.Partition partition { get; construct; }
    public string parent_path { get; construct; }

    public string? volume_group { get; private set; }

    public PartitionBlock (InstallerDaemon.Partition partition, string parent_path, uint64 sector_size) {
        Object (
            parent_path: parent_path,
            partition: partition
        );
    }

    class construct {
        set_css_name ("block");
    }

    construct {
        volume_group = (partition.filesystem == LVM) ? partition.current_lvm_volume_group : null;

        var image = new Gtk.Image () {
            halign = END,
            valign = END
        };

        child = image;
        tooltip_text = partition.device_path;

        add_css_class (partition.filesystem.to_string ());

        bind_property ("icon", image, "gicon", SYNC_CREATE);
    }

    public uint64 get_partition_size () {
        return partition.end_sector - partition.start_sector;
    }
}
