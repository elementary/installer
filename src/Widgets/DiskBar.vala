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
        var name_label = new Granite.HeaderLabel (disk.name) {
            // Calculate the actual size of the disk in bytes for the label
            secondary_text = "%s %s".printf (disk.device_path, GLib.format_size (disk.sectors * disk.sector_size))
        };

        var bar = new PartitionContainer (disk.sectors, partitions);

        var legend_box = new Gtk.Box (VERTICAL, 6) {
            halign = START
        };

        foreach (PartitionBlock partition_block in partitions) {
            var legend = new Legend (partition_block.partition, disk.sector_size);
            legend_box.append (legend);

            var click_gesture = new Gtk.GestureClick ();
            click_gesture.released.connect (partition_block.menu.popup);

            legend.add_controller (click_gesture);
        }

        uint64 used_sectors = 0;
        foreach (PartitionBlock partition in partitions) {
            used_sectors += partition.get_partition_size_in_sectors ();
        }

        // If more than 1% of the disk is unused, show a legend for the unused space
        if ((double)(disk.sectors - used_sectors) / disk.sectors > 0.01) {
            var legend = new Legend.unused ((disk.sectors - used_sectors) * disk.sector_size);
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
        public uint64 total_disk_sectors { get; construct; }

        private Gtk.ConstraintGuide guide;

        public PartitionContainer (uint64 total_disk_sectors, Gee.ArrayList<PartitionBlock> partitions) {
            Object (
                total_disk_sectors: total_disk_sectors,
                partitions: partitions
            );
        }

        class construct {
            set_layout_manager_type (typeof (Gtk.ConstraintLayout));
        }

        construct {
            guide = new Gtk.ConstraintGuide () {
                max_width = 300,
                min_width = 300,
                nat_width = 600
            };

            var layout_manager = ((Gtk.ConstraintLayout) get_layout_manager ());
            layout_manager.add_guide (guide);

            layout_manager.add_constraint (
                new Gtk.Constraint (
                    guide,
                    HEIGHT,
                    EQ,
                    this,
                    HEIGHT,
                    1.0,
                    0.0,
                    Gtk.ConstraintStrength.REQUIRED
                )
            );

            uint64 used_sectors = 0;
            foreach (var partition in partitions) {
                double percent_requested = (double) partition.get_partition_size_in_sectors () / total_disk_sectors;

                used_sectors += partition.get_partition_size_in_sectors ();

                append_partition (
                    partition,
                    percent_requested
                );
            }

            // make sure if somehow used_sectors > total_disk_sectors, we clamp it to total_disk_sectors
            used_sectors = uint64.min (used_sectors, total_disk_sectors);

            // If more than 1% of the disk is unused, show a block for the unused space
            var unused_sectors = total_disk_sectors - used_sectors;
            if ((double) unused_sectors / total_disk_sectors > 0.01) {
                var unused_bar = new Block ();
                unused_bar.add_css_class ("unused");

                append_partition (unused_bar, (double) unused_sectors / total_disk_sectors);
            }

            // Position last child at end
            layout_manager.add_constraint (
                new Gtk.Constraint (
                    null,
                    END,
                    EQ,
                    get_last_child (),
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
            // Truncate to 2 decimal places (round down), to ensure we don't go over 100% because of rounding errors.
            // Also make sure percentage is never 0, otherwise we can assertion error:
            // gtk_constraint_expression_new_subject: assertion failed: (!G_APPROX_VALUE (term->coefficient, 0.0, 0.001)) 
            // Also we assume partitions.size is less than 100
            percentage = ((int) (percentage * 100) / 100.0).clamp (0.01, 1.0 - partitions.size / 100.0);

            widget.set_parent (this);

            var layout_manager = ((Gtk.ConstraintLayout) get_layout_manager ());

            // Fill height of this
            layout_manager.add_constraint (
                new Gtk.Constraint (
                    widget,
                    HEIGHT,
                    EQ,
                    guide,
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
                    guide,
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
                        null,
                        START,
                        EQ,
                        widget,
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
                        1,
                        0,
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

        public Legend (InstallerDaemon.Partition partition, uint64 sector_size) {
            Object (
                ppath: partition.device_path,
                // Calculate the actual size of the partition in bytes for the label
                size: (partition.end_sector - partition.start_sector) * sector_size,
                fs: partition.filesystem.to_string (),
                vg: partition.filesystem == LVM ? partition.current_lvm_volume_group : null
            );
        }

        public Legend.unused (uint64 size_in_bytes) {
            Object (
                ppath: "unused",
                size: size_in_bytes,
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
