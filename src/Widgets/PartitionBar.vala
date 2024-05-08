/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class Installer.PartitionBar : Gtk.EventBox {
    public signal void decrypted (InstallerDaemon.LuksCredentials credential);

    public Icon? icon { get; set; default = null; }

    public bool lvm { get; construct; }
    public InstallerDaemon.Partition partition { get; construct; }
    public string parent_path { get; construct; }

    public string? volume_group { get; private set; }
    public Gtk.Popover menu { get; private set; }

    private Gtk.GestureMultiPress click_gesture;

    public PartitionBar (
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
            menu = new PartitionMenu (partition.device_path, parent_path, partition.filesystem, lvm, set_mount, unset_mount, mount_set, this);
        }

        menu.relative_to = this;
        menu.position = BOTTOM;

        click_gesture = new Gtk.GestureMultiPress (this);
        click_gesture.released.connect (menu.popup);
    }

    class construct {
        set_css_name ("block");
    }

    construct {
        volume_group = (partition.filesystem == LVM) ? partition.current_lvm_volume_group : null;

        var image = new Gtk.Image () {
            hexpand = true,
            halign = END,
            valign = END
        };

        add (image);
        hexpand = true;
        tooltip_text = partition.device_path;

        get_style_context ().add_class (Distinst.strfilesys (partition.filesystem));

        bind_property ("icon", image, "gicon", SYNC_CREATE);
    }

    public uint64 get_size () {
        return partition.end_sector - partition.start_sector;
    }

    public int calculate_length (int alloc_width, uint64 disk_sectors) {
        var percent = ((double) get_size () / (double) disk_sectors);
        var request = alloc_width * percent;
        if (request < 20) request = 20;
        return (int) request;
    }
}
