/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class Installer.DiskBar: Gtk.Box {
    public InstallerDaemon.Disk disk { get; construct; }
    public Gee.ArrayList<PartitionBlock> partitions { get; construct; }

    public DiskBar (InstallerDaemon.Disk disk, Gee.ArrayList<PartitionBlock> partitions) {
        Object (
            disk: disk,
            partitions: partitions
        );
    }

    class construct {
        set_css_name ("levelbar");
    }

    construct {
        var size = disk.sectors * disk.sector_size;

        var name_label = new Granite.HeaderLabel (disk.name) {
            secondary_text = "%s %s".printf (disk.device_path, GLib.format_size (size))
        };

        var bar = new PartitionContainer (size, partitions);

        var legend_box = new Gtk.Box (VERTICAL, 6) {
            halign = START
        };

        foreach (PartitionBlock partition_block in partitions) {
            var legend = new Legend (partition_block.partition);
            legend_box.append (legend);

            var click_gesture = new Gtk.GestureClick ();
            click_gesture.released.connect (partition_block.menu.popup);

            legend.add_controller (click_gesture);
        }

        uint64 used = 0;
        foreach (PartitionBlock partition in partitions) {
            used += partition.get_partition_size ();
        }

        var unused = size - (used * 512);
        if (size / 100 < unused) {
            var legend = new Legend.unused (unused);
            legend_box.append (legend);
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

    private class PartitionContainer : Gtk.Widget {
        public Gee.ArrayList<PartitionBlock> partitions { get; construct; }
        public uint64 size { get; construct; }

        public PartitionContainer (uint64 size, Gee.ArrayList<PartitionBlock> partitions) {
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

    private class Legend : Gtk.Grid {
        public string ppath { get; construct; }
        public uint64 size { get; construct; }
        public string fs { get; construct; }
        public string? vg { get; construct; default = null; }

        public Legend (InstallerDaemon.Partition partition) {
            Object (
                ppath: partition.device_path,
                size: (partition.end_sector - partition.start_sector) * 512,
                fs: partition.filesystem.to_string (),
                vg: partition.filesystem == LVM ? partition.current_lvm_volume_group : null
            );
        }

        public Legend.unused (uint64 size) {
            Object (
                ppath: "unused",
                size: size,
                fs: "unused"
            );
        }

        construct {
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

            column_spacing = 12;
            attach (fill_round, 0, 0, 1, 2);
            attach (path, 1, 0);
            attach (info, 1, 1);
        }
    }

    private class Block : Gtk.Grid {
        class construct {
            set_css_name ("block");
        }
    }
}
