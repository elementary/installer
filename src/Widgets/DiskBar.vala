/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class Installer.DiskBar: Gtk.Box {
    public string disk_name { get; construct; }
    public string disk_path { get; construct; }
    public uint64 size { get; construct; }
    public Gee.ArrayList<PartitionBar> partitions { get; construct; }

    private Gtk.Box legend_box;

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

    construct {
        var name_label = new Granite.HeaderLabel (disk_name) {
            secondary_text = "%s %s".printf (disk_path, GLib.format_size (size))
        };

        var bar = new PartitionContainer (size, partitions);

        legend_box = new Gtk.Box (VERTICAL, 6) {
            halign = START
        };

        foreach (PartitionBar p in partitions) {
            add_legend (
                p.partition.device_path,
                p.get_partition_size () * 512,
                p.partition.filesystem.to_string (),
                p.volume_group,
                p.menu
            );
        }

        uint64 used = 0;
        foreach (PartitionBar partition in partitions) {
            used += partition.get_partition_size ();
        }

        var unused = size - (used * 512);
        if (size / 100 < unused) {
            add_legend ("unused", unused, "unused", null, null);
        }

        orientation = VERTICAL;
        hexpand = true;
        spacing = 12;
        append (name_label );
        append (bar);
        append (legend_box);

        // Lie about orientation for styling reasons
        css_classes = {"horizontal"};
    }

    private void add_legend (string ppath, uint64 size, string fs, string? vg, Gtk.Popover? menu) {
        var fill_round = new Block () {
            valign = CENTER
        };
        fill_round.add_css_class ("legend");
        fill_round.add_css_class (fs);

        var format_size = GLib.format_size (size);

        var info = new Gtk.Label (
            (vg == null)
                ? _("%s (%s)").printf (format_size, fs)
                : _("%s (%s: <b>%s</b>)").printf (format_size, fs, vg)
        ) {
            halign = START,
        };
        info.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        info.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        info.use_markup = true;

        var path = new Gtk.Label (ppath) {
            halign = START
        };

        var legend = new Gtk.Grid () {
            column_spacing = 12
        };
        legend.attach (fill_round, 0, 0, 1, 2);
        legend.attach (path, 1, 0);
        legend.attach (info, 1, 1);

        if (menu != null) {
            var click_gesture = new Gtk.GestureClick ();
            click_gesture.released.connect (menu.popup);

            legend.add_controller (click_gesture);
        }

        legend_box.append (legend);
    }

    private class PartitionContainer : Gtk.Widget {
        public Gee.ArrayList<PartitionBar> partitions { get; construct; }
        public uint64 size { get; construct; }

        public PartitionContainer (uint64 size, Gee.ArrayList<PartitionBar> partitions) {
            Object (
                partitions: partitions,
                size: size
            );
        }

        class construct {
            set_layout_manager_type (typeof (Gtk.ConstraintLayout));
        }

        construct {
            uint64 used = 0;
            var disk_sectors = size / 512;
            foreach (var partition in partitions) {
                double percent_requested = (double) partition.get_partition_size () / disk_sectors;
                percent_requested = percent_requested.clamp (0.01, 0.99);

                used += partition.get_partition_size ();

                append_partition (
                    partition,
                    percent_requested
                );
            }

            var unused = size - (used * 512);
            if (size / 100 < unused) {
                var unused_bar = new Block ();
                unused_bar.add_css_class ("unused");

                append_partition (unused_bar, unused / size);
            }

            var layout_manager = ((Gtk.ConstraintLayout) get_layout_manager ());
            // Position last child at end
            layout_manager.add_constraint (
                new Gtk.Constraint (
                    get_last_child (),
                    END,
                    EQ,
                    this,
                    END,
                    1.0,
                    0.0,
                    Gtk.ConstraintStrength.REQUIRED
                )
            );
        }

        ~PartitionContainer () {
            while (get_first_child () != null) {
                get_first_child ().unparent ();
            }
        }

        private void append_partition (Gtk.Widget widget, double percentage) {
            widget.set_parent (this);

            var layout_manager = ((Gtk.ConstraintLayout) get_layout_manager ());

            // Fill height of this
            layout_manager.add_constraint (
                new Gtk.Constraint (
                    widget,
                    HEIGHT,
                    EQ,
                    this,
                    HEIGHT,
                    1.0,
                    0.0,
                    Gtk.ConstraintStrength.REQUIRED
                )
            );

            // Fill width based on partition size
            layout_manager.add_constraint (
                new Gtk.Constraint (
                    widget,
                    WIDTH,
                    EQ,
                    this,
                    WIDTH,
                    percentage,
                    0,
                    Gtk.ConstraintStrength.STRONG
                )
            );

            var previous_child = widget.get_prev_sibling ();
            if (previous_child == null) {
                // Position at start
                layout_manager.add_constraint (
                    new Gtk.Constraint (
                        widget,
                        START,
                        EQ,
                        this,
                        START,
                        1.0,
                        0.0,
                        Gtk.ConstraintStrength.REQUIRED
                    )
                );
            } else {
                // Position end to end
                layout_manager.add_constraint (
                    new Gtk.Constraint (
                        widget,
                        START,
                        EQ,
                        previous_child,
                        END,
                        1.0,
                        0.0,
                        Gtk.ConstraintStrength.REQUIRED
                    )
                );
            }
        }
    }

    private class Block : Gtk.Grid {
        class construct {
            set_css_name ("block");
        }
    }
}
