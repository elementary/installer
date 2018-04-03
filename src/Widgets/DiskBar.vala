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

public class Installer.DiskBar: Gtk.Box {
    public string disk_name;
    public string disk_path;
    public uint64 size;

    public Gtk.Box label;

    public DiskBar (
        string model,
        string path,
        uint64 size,
        GLib.Array<PartitionBar> partitions
    ) {
        this.disk_name = model;
        this.disk_path = path;
        this.size = size;

        generate_label ();
        generate_bar (partitions);
    }

    construct {
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.hexpand = true;
        this.get_style_context ().add_class("disk-bar");
    }

    private void generate_label () {
        var name_label = new Gtk.Label (disk_name);
        var size_label = new Gtk.Label ("<small>%s %s</small>".printf (disk_path, GLib.format_size (size)));
        size_label.use_markup = true;
        size_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        label = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        label.pack_start (name_label, false, false, 0);
        label.pack_start (size_label, false, false, 0);
        label.set_margin_right (12);
        label.valign = Gtk.Align.CENTER;
    }

    private void generate_bar (GLib.Array<PartitionBar> partitions) {
        for (int i = 0; i < partitions.length ; i++) {
            var part = partitions.index(i);
            this.pack_start(part, true, true, 0);
        }

        this.size_allocate.connect ((alloc) => {
            update_sector_lengths (partitions, alloc.width);
        });

        GLib.Idle.add (() => {
            var alloc = Gtk.Allocation ();
            this.get_allocation (out alloc);
            update_sector_lengths (partitions, alloc.width);
            return GLib.Source.REMOVE;
        });
    }

    public void update_sector_lengths (GLib.Array<PartitionBar> partitions, int alloc_width) {
        var disk_sectors = this.size / 512;
        for (int i = 0; i < partitions.length ; i++) {
            partitions.index (i).update_length (alloc_width, disk_sectors);
        }
    }
}
