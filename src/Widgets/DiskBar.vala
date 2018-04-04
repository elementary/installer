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

public class Installer.DiskBar: Gtk.Grid {
    public string disk_name { get; construct; }
    public string disk_path { get; construct; }
    public uint64 size { get; construct; }
    public GLib.Array<PartitionBar> partitions { get; construct; }

    private Gtk.Box label;
    private Gtk.Box bar;
    private Gtk.Box legend_container;
    private Gtk.Box bar_container;
    private uint64 unused;
    private Gtk.Box unused_bar;

    public DiskBar (
        string model,
        string path,
        uint64 size,
        GLib.Array<PartitionBar> partitions
    ) {
        Object (
            disk_name: model,
            disk_path: path,
            partitions: partitions,
            size: size
        );
    }

    construct {
        unused = get_unused ();
        generate_label ();
        generate_bar ();
        generate_legend ();

        var description = new Gtk.Label ("%s free out of %s".printf (
            GLib.format_size (unused),
            GLib.format_size (size)
        ));
        description.set_halign (Gtk.Align.CENTER);

        this.hexpand = true;
        this.row_spacing = 6;
        this.get_style_context ().add_class ("storage-bar");
        this.attach (label, 0, 1);
        this.attach (legend_container, 1, 0);
        this.attach (bar, 1, 1);
        this.attach (description, 1, 2);
        this.margin = 6;

        show_all ();
    }

    private uint64 get_unused () {
        uint64 used = 0;
        for (int i = 0; i < partitions.length; i++) {
            used += partitions.index (i).get_size ();
        }

        return size - (used * 512);
    }

    private void generate_legend () {
        legend_container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        legend_container.set_halign (Gtk.Align.CENTER);

        for (int i = 0; i < partitions.length; i++) {
            var p = partitions.index (i);
            add_legend (p.path, p.get_size() * 512, Distinst.strfilesys (p.filesystem));
        }

        add_legend ("unused", unused, "unused");
    }

    private void add_legend (string ppath, uint64 size, string fs) {
        var fill_round = new FillRound ();
        fill_round.set_valign(Gtk.Align.CENTER);

        var context = fill_round.get_style_context ();
        context.add_class ("legend");
        context.add_class (fs);

        var info = new Gtk.Label ("%s (%s)".printf (GLib.format_size (size), fs));
        var path = new Gtk.Label ("<b>%s</b>".printf (ppath));
        path.use_markup = true;

        var legend = new Gtk.Grid ();
        legend.row_spacing = 3;
        legend.column_spacing = 6;
        legend.attach (fill_round, 0, 0, 1, 2);
        legend.attach (path, 1, 0);
        legend.attach (info, 1, 1);

        legend_container.pack_start(legend, false, false, 0);
    }

    private void generate_label () {
        var name_label = new Gtk.Label ("<b>%s</b>".printf (disk_name));
        name_label.set_halign (Gtk.Align.END);
        name_label.use_markup = true;

        var size_label = new Gtk.Label ("<small>%s %s</small>".printf (disk_path, GLib.format_size (size)));
        size_label.set_halign (Gtk.Align.END);
        size_label.use_markup = true;
        size_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        label = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        label.pack_start (name_label, false, false, 0);
        label.pack_start (size_label, false, false, 0);
        label.set_margin_right (12);
        label.valign = Gtk.Align.CENTER;
    }

    private void generate_bar () {
        bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bar.set_size_request (-1, 40);
        bar.get_style_context ().add_class ("trough");
        bar.get_style_context ().add_class ("disk-bar");
        unused_bar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        var context = unused_bar.get_style_context ();
        context.add_class ("unused");

        bar.size_allocate.connect ((alloc) => {
            update_sector_lengths (partitions, alloc.width);
        });

        for (int i = 0; i < partitions.length; i++) {
            var part = partitions.index (i);
            part.update_length (1000, this.size / 512);
            bar.pack_start(part, false, false, 0);
        }

        bar.pack_start (unused_bar, true, true, 0);
    }

    public void update_sector_lengths (GLib.Array<PartitionBar> partitions, int alloc_width) {
        var disk_sectors = this.size / 512;
        for (int i = 0; i < partitions.length; i++) {
            partitions.index (i).update_length (alloc_width, disk_sectors);
        }

        var unused_size = unused / 512;
        int percent = (int) (((double) unused_size / (double) disk_sectors) * 100);
        var request = alloc_width / 100 * (int) percent;
        unused_bar.set_size_request (request, -1);
    }

    internal class FillRound : Gtk.Widget {
        internal FillRound () {

        }

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
