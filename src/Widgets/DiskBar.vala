/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class Installer.DiskBar: Gtk.Grid {
    public string disk_name { get; construct; }
    public string disk_path { get; construct; }
    public uint64 size { get; construct; }
    public Gee.ArrayList<PartitionBar> partitions { get; construct; }

    private static Gtk.SizeGroup label_sizegroup;

    private Gtk.Box legend_container;

    public DiskBar (string disk_name, string disk_path, uint64 size, Gee.ArrayList<PartitionBar> partitions) {
        Object (
            disk_name: disk_name,
            disk_path: disk_path,
            partitions: partitions,
            size: size
        );
    }

    class construct {
        set_css_name ("levelbar");
    }

    static construct {
        label_sizegroup = new Gtk.SizeGroup (HORIZONTAL);
    }

    construct {
        var name_label = new Gtk.Label ("<b>%s</b>".printf (disk_name)) {
            xalign = 1,
            use_markup = true
        };

        var size_label = new Gtk.Label ("%s %s".printf (disk_path, GLib.format_size (size))) {
            xalign = 1
        };
        size_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        size_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var label_box = new Gtk.Box (VERTICAL, 6) {
            valign = CENTER
        };
        label_box.add (name_label);
        label_box.add (size_label);

        label_sizegroup.add_widget (name_label);
        label_sizegroup.add_widget (size_label);

        var bar = new Gtk.Grid ();

        bar.size_allocate.connect ((alloc) => {
            update_sector_lengths (partitions, alloc);
        });

        foreach (PartitionBar part in partitions) {
            bar.add (part);
        }

        legend_container = new Gtk.Box (HORIZONTAL, 24) {
            halign = CENTER,
            margin_bottom = 9
        };

        var legend = new Gtk.ScrolledWindow (null, null) {
            child = legend_container,
            vscrollbar_policy = NEVER
        };

        foreach (PartitionBar p in partitions) {
            add_legend (
                p.partition.device_path,
                p.get_size () * 512,
                Distinst.strfilesys (p.partition.filesystem),
                p.volume_group,
                p.menu
            );
        }

        uint64 used = 0;
        foreach (PartitionBar partition in partitions) {
            used += partition.get_size ();
        }

        var unused = size - (used * 512);
        if (size / 100 < unused) {
            add_legend ("unused", unused, "unused", null, null);

            var unused_bar = new Block () {
                hexpand = true,
                vexpand = true
            };
            unused_bar.get_style_context ().add_class ("unused");

            bar.add (unused_bar);
        }

        column_spacing = 12;
        hexpand = true;
        get_style_context ().add_class (Granite.STYLE_CLASS_STORAGEBAR);
        attach (label_box, 0, 1);
        attach (legend, 1, 0);
        attach (bar, 1, 1);

        show_all ();
    }

    private void add_legend (string ppath, uint64 size, string fs, string? vg, Gtk.Popover? menu) {
        var fill_round = new Block () {
            valign = CENTER
        };
        fill_round.get_style_context ().add_class ("legend");
        fill_round.get_style_context ().add_class (fs);

        var format_size = GLib.format_size (size);

        var info = new Gtk.Label (
            (vg == null)
                ? _("%s (%s)").printf (format_size, fs)
                : _("%s (%s: <b>%s</b>)").printf (format_size, fs, vg)
        );
        info.use_markup = true;

        var path = new Gtk.Label ("<b>%s</b>".printf (ppath)) {
            halign = START,
            use_markup = true
        };

        var legend = new Gtk.Grid () {
            column_spacing = 6
        };
        legend.attach (fill_round, 0, 0, 1, 2);
        legend.attach (path, 1, 0);
        legend.attach (info, 1, 1);

        var event_box = new Gtk.EventBox ();
        event_box.add (legend);
        event_box.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);

        if (menu != null) {
            event_box.button_press_event.connect (() => {
                menu.popup ();
                return true;
            });
        }

        legend_container.add (event_box);
    }

    private void update_sector_lengths (Gee.ArrayList<PartitionBar> partitions, Gtk.Allocation alloc) {
        var alloc_width = alloc.width;
        var disk_sectors = this.size / 512;

        int[] lengths = {};
        for (int x = 0; x < partitions.size; x++) {
            var part = partitions[x];
            var requested = part.calculate_length (alloc_width, disk_sectors);

            var excess = requested - alloc_width;
            while (excess > 0) {
                var reduce_by = x / excess;
                if (reduce_by == 0) reduce_by = 1;

                // Begin by resizing all partitions over 20px wide.
                bool excess_modified = false;
                for (int y = 0; excess > 0 && y < x; y++) {
                    if (lengths[y] <= 20) continue;
                    lengths[y] -= reduce_by;
                    excess -= reduce_by;
                    excess_modified = true;
                }

                // In case all are below that width, shrink beyond limit.
                if (!excess_modified) {
                    for (int y = 0; excess > 0 && y < x; y++) {
                        lengths[y] -= reduce_by;
                        excess -= reduce_by;
                        excess_modified = true;
                    }
                }
            }

            alloc_width -= requested;
            disk_sectors -= part.get_size ();
            lengths += requested;
        }

        var new_alloc = Gtk.Allocation ();
        new_alloc.x = alloc.x;
        new_alloc.y = alloc.y;
        new_alloc.height = alloc.height;
        for (int x = 0; x < partitions.size; x++) {
            new_alloc.width = lengths[x];
            partitions[x].size_allocate (new_alloc);
            new_alloc.x += new_alloc.width;
        }
    }

    private class Block : Gtk.Grid {
        class construct {
            set_css_name ("block");
        }
    }
}
