/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class Installer.PartitionBlock : Adw.Bin {
    public signal void decrypted (InstallerDaemon.LuksCredentials credential);

    public Icon? icon { get; set; default = null; }

    public bool lvm { get; construct; }
    public InstallerDaemon.Partition partition { get; construct; }
    public string parent_path { get; construct; }

    public string? volume_group { get; private set; }
    public Gtk.Popover menu { get; private set; }

    public PartitionBlock (
        InstallerDaemon.Partition partition,
        string parent_path,
        uint64 sector_size,
        bool lvm,
        SetMount set_mount,
        UnsetMount unset_mount,
        MountSetFn mount_set
    ) {
        Object (
            lvm: lvm,
            parent_path: parent_path,
            partition: partition
        );

        if (partition.filesystem == LUKS) {
            menu = new DecryptMenu (partition.device_path);
            ((DecryptMenu)menu).decrypted.connect ((creds) => decrypted (creds));
        } else {
            menu = new PartitionMenu (partition, parent_path, lvm, set_mount, unset_mount, mount_set, this);
        }

        menu.set_parent (this);
        menu.position = BOTTOM;

        var click_gesture = new Gtk.GestureClick ();
        click_gesture.released.connect (menu.popup);

        add_controller (click_gesture);
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
