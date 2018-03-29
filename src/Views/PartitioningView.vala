// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class Installer.PartitioningView : AbstractInstallerView  {
    public signal void next_step ();

    private Gtk.Button next_button;
    private Distinst.Disks disks;
    private GLib.Array<PartitionBar> partitions;

    public GLib.Array<Installer.Mount> mounts;

    public static uint64 minimum_disk_size;

    public PartitioningView (uint64 size) {
        minimum_disk_size = size;
        Object (cancellable: true);
    }

    construct {
        this.mounts = new GLib.Array<Installer.Mount> ();
        this.margin = 24;
        var disk_list = new Gtk.Grid ();
        disk_list.row_spacing = 24;
        var disk_scroller = new Gtk.ScrolledWindow (null, null);
        disk_scroller.expand = true;
        disk_scroller.vscrollbar_policy = Gtk.PolicyType.NEVER;
        disk_scroller.add (disk_list);

        var description = new Gtk.Label (_("Select which partitions to use across all drives. This will erase all data on the selected partitions."));

        this.content_area.attach(description, 0, 0, 1, 1);
        this.content_area.attach(disk_scroller, 0, 1, 1, 1);

        disks = Distinst.Disks.probe ();
        var id = 0;
        foreach (unowned Distinst.Disk disk in disks.list ()) {
            // Skip root disk or live disk
            if (disk.contains_mount ("/") || disk.contains_mount ("/cdrom")) {
                continue;
            }

            var sector_size = disk.get_sector_size ();
            var size = disk.get_sectors () * sector_size;

            string path = Utils.string_from_utf8(disk.get_device_path ());

            string label;
            string model = disk.get_model ();
            if (model.length == 0) {
                label = disk.get_serial ().replace ("_", " ");
            } else {
                label = model;
            }

            partitions = new GLib.Array<PartitionBar> ();
            foreach (unowned Distinst.Partition part in disk.list_partitions ()) {
                var partition = new PartitionBar (part, path, sector_size, this.set_mount, this.unset_mount);
                partitions.append_val (partition);
            }

            for (int i = 0; i < partitions.length ; i++) {
                var part = partitions.index(i);
                part.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
                part.button_press_event.connect (() => {
                    part.show_popover();
                });
            }

            var disk_bar = new DiskBar (model, path, size, partitions);
            disk_list.attach(disk_bar.label, 0, id, 1, 1);
            disk_list.attach(disk_bar, 1, id, 1, 1);

            id += 1;
        }

        next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;
        next_button.clicked.connect (() => next_step ());

        action_area.add (next_button);

        show_all ();
    }

    private void validate_status () {
        uint8 flags = 0;
        const uint8 ROOT = 1;
        const uint8 BOOT = 2;

        for (int i = 0; i < mounts.length; i++) {
            var m = mounts.index (i);

            if (m.mount_point == "/") {
                flags |= ROOT;
            } else if (m.mount_point == "/boot/efi" && m.has_esp_fs ()) {
                flags |= BOOT;
            }

            if (flags == ROOT + BOOT) {
                next_button.sensitive = true;
                return;
            }
        }

        next_button.sensitive = false;
    }

    private void set_mount (Mount mount) {
        for (int i = 0; i < mounts.length; i++) {
            var m = mounts.index (i);
            if (m.partition_path == mount.partition_path) {
                m = mount;
                validate_status ();
                return;
            }
        }

        this.mounts.append_val (mount);
        validate_status ();
    }

    private void unset_mount (string partition) {
        var found_mount = false;
        int i = 0;
        for (; i < mounts.length; i++) {
            var m = mounts.index (i);
            if (m.partition_path == partition) {
                found_mount = true;
                break;
            }
        }

        if (found_mount) {
            mounts.remove_index (i);
        }

        validate_status ();
    }
}
