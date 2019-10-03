// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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

public class Installer.DiskBar: Gtk.Grid {
    public string disk_name { get; construct; }
    public string disk_path { get; construct; }
    public uint64 size { get; construct; }
    public Gee.ArrayList<PartitionBar> partitions { get; construct; }

    public Gtk.Grid label { get; private set; }
    private Gtk.Grid legend_container;

    public DiskBar (string disk_name, string disk_path, uint64 size, Gee.ArrayList<PartitionBar> partitions) {
        Object (
            disk_name: disk_name,
            disk_path: disk_path,
            partitions: partitions,
            size: size
        );
    }

    construct {
        var name_label = new Gtk.Label ("<b>%s</b>".printf (disk_name));
        name_label.halign = Gtk.Align.END;
        name_label.use_markup = true;

        var size_label = new Gtk.Label ("<small>%s %s</small>".printf (disk_path, GLib.format_size (size)));
        size_label.halign = Gtk.Align.END;
        size_label.use_markup = true;
        size_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        label = new Gtk.Grid ();
        label.orientation = Gtk.Orientation.VERTICAL;
        label.row_spacing = 6;
        label.margin_end = 12;
        label.valign = Gtk.Align.CENTER;
        label.add (name_label);
        label.add (size_label);

        var bar = new Gtk.Grid ();
        bar.width_request = 40;

        var bar_style_context = bar.get_style_context ();
        bar_style_context.add_class (Gtk.STYLE_CLASS_TROUGH);
        bar_style_context.add_class ("disk-bar");

        bar.size_allocate.connect ((alloc) => {
            update_sector_lengths (partitions, alloc);
        });

        foreach (PartitionBar part in partitions) {
            bar.add (part);
        }

        legend_container = new Gtk.Grid ();
        legend_container.column_spacing = 12;
        legend_container.halign = Gtk.Align.CENTER;
        legend_container.margin_bottom = 9;

        var legend = new Gtk.ScrolledWindow (null, null);
        legend.vscrollbar_policy = Gtk.PolicyType.NEVER;
        legend.add (legend_container);

        foreach (PartitionBar p in partitions) {
            add_legend (p.path, p.get_size () * 512, Distinst.strfilesys (p.filesystem), p.vg, p.menu);
        }

        uint64 used = 0;
        foreach (PartitionBar partition in partitions) {
            used += partition.get_size ();
        }

        var unused = size - (used * 512);
        if (size / 100 < unused) {
            add_legend ("unused", unused, "unused", null, null);

            var unused_bar = new Gtk.Grid ();
            unused_bar.expand = true;

            var unused_style_context = unused_bar.get_style_context ();
            unused_style_context.add_class ("fill-block");
            unused_style_context.add_class ("unused");

            bar.add (unused_bar);
        }

        hexpand = true;
        margin = 6;
        get_style_context ().add_class (Granite.STYLE_CLASS_STORAGEBAR);
        attach (label, 0, 1);
        attach (legend, 1, 0);
        attach (bar, 1, 1);

        show_all ();
    }

    private void add_legend (string ppath, uint64 size, string fs, string? vg, Gtk.Popover? menu) {
        var fill_round = new FillRound ();
        fill_round.width_request = fill_round.height_request = 14;
        fill_round.valign = Gtk.Align.CENTER;

        var context = fill_round.get_style_context ();
        context.add_class ("legend");
        context.add_class (fs);

        var format_size = GLib.format_size (size);

        var info = new Gtk.Label (
            (vg == null)
                ? _("%s (%s)").printf (format_size, fs)
                : _("%s (%s: <b>%s</b>)").printf (format_size, fs, vg)
        );
        info.use_markup = true;

        var path = new Gtk.Label ("<b>%s</b>".printf (ppath));
        path.halign = Gtk.Align.START;
        path.use_markup = true;

        var legend = new Gtk.Grid ();
        legend.column_spacing = 6;
        legend.attach (set_menu (fill_round, menu), 0, 0, 1, 2);
        legend.attach (set_menu (path, menu), 1, 0);
        legend.attach (info, 1, 1);

        legend_container.add (legend);
    }

    private Gtk.Widget set_menu (Gtk.Widget widget, Gtk.Popover? menu) {
        if (menu != null) {
            var event_box = new Gtk.EventBox ();
            event_box.add (widget);
            event_box.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
            event_box.button_press_event.connect (() => {
                menu.popup ();
                return true;
            });
            return event_box;
        }

        return widget;
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

    internal class FillRound : Gtk.Widget {
        construct {
            set_has_window (false);
            var style_context = get_style_context ();
            style_context.add_class ("fill-block");
            expand = true;
        }

        public override bool draw (Cairo.Context cr) {
            var width = get_allocated_width ();
            var height = get_allocated_height ();
            var context = get_style_context ();
            context.render_background (cr, 0, 0, width, height);
            context.render_frame (cr, 0, 0, width, height);
            return true;
        }

        public override void get_preferred_width (out int minimum_width, out int natural_width) {
            base.get_preferred_width (out minimum_width, out natural_width);
            var context = get_style_context ();
            var padding = context.get_padding (get_state_flags ());
            minimum_width = int.max (padding.left + padding.right, minimum_width);
            minimum_width = int.max (1, minimum_width);
            natural_width = int.max (minimum_width, natural_width);
        }

        public override void get_preferred_height (out int minimum_height, out int natural_height) {
            base.get_preferred_height (out minimum_height, out natural_height);
            var context = get_style_context ();
            var padding = context.get_padding (get_state_flags ());
            minimum_height = int.max (padding.top + padding.bottom, minimum_height);
            minimum_height = int.max (1, minimum_height);
            natural_height = int.max (minimum_height, natural_height);
        }
    }
}
