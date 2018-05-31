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

public delegate string? SetMount (Installer.Mount mount);

public delegate void UnsetMount (string partition);

public delegate bool MountSetFn (string mount_point);

public class Installer.PartitionMenu : Gtk.Popover {
    public bool disable_signals;
    public bool is_lvm;
    public Gtk.ComboBoxText type;
    public Gtk.ComboBoxText use_as;
    public Gtk.Entry custom;
    public Gtk.Label custom_label;
    public Gtk.Label format_label;
    public Gtk.Switch format_partition;
    public Gtk.Label type_label;
    public Gtk.Switch use_partition;
    public Distinst.FileSystemType original_filesystem;
    public string parent_disk;
    public string partition_path;

    // A reference to the parent which owns this menu.
    private PartitionBar partition_bar;

    public PartitionMenu (string path, string parent, Distinst.FileSystemType fs,
                          bool lvm, SetMount set_mount, UnsetMount unset_mount,
                          MountSetFn mount_set, PartitionBar partition_bar) {
        this.partition_bar = partition_bar;
        original_filesystem = fs;
        is_lvm = lvm;
        partition_path = path;
        parent_disk = parent;

        string boot_partition = (Distinst.bootloader_detect () == Distinst.PartitionTable.GPT)
            ? "/boot/efi"
            : "/boot";

        var label_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

        var use_partition_label = new Gtk.Label (_("Use partition:"));
        use_partition_label.halign = Gtk.Align.END;
        use_partition_label.xalign = 1;
        label_size_group.add_widget (use_partition_label);

        use_partition = new Gtk.Switch ();
        use_partition.halign = Gtk.Align.START;
        use_partition.hexpand = false;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        format_label = new Gtk.Label (_("Format:"));
        format_label.halign = Gtk.Align.END;
        format_label.xalign = 1;
        label_size_group.add_widget (format_label);

        format_partition = new Gtk.Switch ();
        format_partition.halign = Gtk.Align.START;
        format_partition.hexpand = false;
        format_partition.bind_property ("visible", format_label, "visible");

        var use_as_label = new Gtk.Label (_("Use as:"));
        use_as_label.halign = Gtk.Align.END;
        use_as_label.xalign = 1;
        label_size_group.add_widget (use_as_label);

        use_as = new Gtk.ComboBoxText ();
        use_as.append_text (_("Root (/)"));
        use_as.append_text (_("Home (/home)"));
        use_as.append_text (_("Boot (%s)".printf (boot_partition)));
        use_as.append_text (_("Swap"));
        use_as.append_text (_("Custom"));
        use_as.active = 0;
        use_as.bind_property ("visible", use_as_label, "visible");

        custom_label = new Gtk.Label (_("Custom:"));
        custom_label.halign = Gtk.Align.END;
        custom_label.xalign = 1;
        label_size_group.add_widget (custom_label);

        custom = new Gtk.Entry ();
        custom.bind_property ("visible", custom_label, "visible");

        type_label = new Gtk.Label (_("Filesystem:"));
        type_label.halign = Gtk.Align.END;
        type_label.xalign = 1;
        label_size_group.add_widget (type_label);

        type = new Gtk.ComboBoxText ();
        type.append_text (_("Default (ext4)"));
        type.append_text ("fat16");
        type.append_text ("fat32");
        type.append_text ("btrfs");
        type.append_text ("xfs");
        type.append_text ("ntfs");
        type.active = 0;
        type.bind_property ("visible", type_label, "visible");

        var top_controls = new Gtk.Grid ();
        top_controls.column_spacing = 12;
        top_controls.row_spacing = 6;
        top_controls.margin = 12;

        top_controls.attach (use_partition_label, 0, 0);
        top_controls.attach (use_partition,       1, 0);

        var bottom_controls = new Gtk.Grid ();
        bottom_controls.column_spacing = 12;
        bottom_controls.row_spacing = 6;
        bottom_controls.margin = 12;
        bottom_controls.margin_top = 6;

        bottom_controls.attach (format_label, 0, 1);
        bottom_controls.attach (use_as_label, 0, 2);
        bottom_controls.attach (custom_label, 0, 3);
        bottom_controls.attach (type_label,   0, 4);

        bottom_controls.attach (format_partition, 1, 1);
        bottom_controls.attach (use_as,           1, 2);
        bottom_controls.attach (custom,           1, 3);
        bottom_controls.attach (type,             1, 4);

        var bottom_grid = new Gtk.Grid ();
        bottom_grid.column_spacing = 12;
        bottom_grid.row_spacing = 6;

        bottom_grid.attach (separator,       0, 0);
        bottom_grid.attach (bottom_controls, 0, 1);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;

        var bottom_revealer = new Gtk.Revealer ();
        bottom_revealer.add (bottom_grid);

        grid.attach (top_controls,    0, 0);
        grid.attach (bottom_revealer, 0, 1);

        add (grid);
        grid.show_all ();

        custom.visible = false;

        format_partition.notify["active"].connect (() => {
            if (!disable_signals) {
                check_values (set_mount);
            }
        });

        use_as.changed.connect (() => {
            if (disable_signals) {
                return;
            }

            var active = use_as.active;
            bool visible = active == 4;

            custom.visible = visible;

            if (active == 2) {
                if (Distinst.bootloader_detect () == Distinst.PartitionTable.GPT) {
                    type.active = 2;
                } else {
                    type.active = 0;
                }
                type.visible = true;
                type.sensitive = false;
                format_partition.visible = true;
            } else if (active == 3) {
                format_partition.visible = false;
                disable_signals = true;
                format_partition.active = true;
                disable_signals = false;
                type.visible = false;
            } else {
                type.visible = true;
                type.sensitive = true;
                format_partition.visible = true;
            }

            check_values (set_mount);
        });

        type.changed.connect (() => {
            if (!disable_signals) {
                check_values (set_mount);
                set_format_sensitivity ();
            }
        });

        custom.changed.connect (() => {
            if (!disable_signals) {
                check_values (set_mount);
            }
        });

        use_partition.notify["active"].connect (() => {
            if (disable_signals) {
                return;
            }

            if (use_partition.active) {
                disable_signals = true;
                set_format_sensitivity ();
                disable_signals = false;

                int select = 0;
                if (fs == Distinst.FileSystemType.FAT16 || fs == Distinst.FileSystemType.FAT32) {
                    if (mount_set (boot_partition)) {
                        select = 4;
                    } else {
                        select = 2;
                    }
                } else if (fs == Distinst.FileSystemType.SWAP) {
                    select = 3;
                } else if (mount_set ("/")) {
                    if (mount_set ("/home" )) {
                        select = 4;
                    } else {
                        select = 1;
                    }
                }
                use_as.set_active (select);
                update_values (set_mount);
            } else {
                unset_mount (partition_path);
                partition_bar.container.get_children ().foreach ((c) => c.destroy ());
            }

            bottom_revealer.reveal_child = use_partition.active;
        });
    }

    public void unset () {
        disable_signals = true;
        use_partition.active = false;
        use_as.active = 0;
        type.active = 0;
        type.sensitive = true;
        type.visible = true;
        custom.visible = false;
        disable_signals = false;
        partition_bar.container.get_children ().foreach ((c) => c.destroy ());
    }

    private void set_format_sensitivity () {
        bool is_sensitive = has_same_filesystem ();
        format_partition.active = !is_sensitive;
        format_partition.sensitive = is_sensitive;
    }

    private void check_values (SetMount set_mount) {
        if (values_ready ()) {
            update_values (set_mount);
        }
    }

    private void update_values (SetMount set_mount) {
        var mount = get_mount ();
        var filesystem = mount == "swap"
            ? Distinst.FileSystemType.SWAP
            : get_file_system ();

        var error = set_mount (new Installer.Mount (
            partition_path,
            parent_disk,
            mount,
            partition_bar.end - partition_bar.start,
            (format_partition.active ? Mount.Flags.FORMAT : 0)
                + (is_lvm ? Mount.Flags.LVM : 0),
            filesystem,
            this
        ));

        var mount_icon = new Gtk.Image.from_icon_name (
            error == null ? "process-completed-symbolic" : "dialog-warning-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        );

        if (error != null) {
            partition_bar.set_tooltip_text (error);
        }

        mount_icon.halign = Gtk.Align.END;
        mount_icon.valign = Gtk.Align.END;
        mount_icon.margin = 6;

        partition_bar.container.get_children ().foreach ((c) => c.destroy ());
        partition_bar.container.pack_start (mount_icon, true, true, 0);
        partition_bar.container.show_all ();
    }

    private bool has_same_filesystem () {
        return original_filesystem == get_file_system ();
    }

    private Distinst.FileSystemType get_file_system () {
        switch (type.active) {
            case 0:
                return Distinst.FileSystemType.EXT4;
            case 1:
                return Distinst.FileSystemType.FAT16;
            case 2:
                return Distinst.FileSystemType.FAT32;
            case 3:
                return Distinst.FileSystemType.BTRFS;
            case 4:
                return Distinst.FileSystemType.XFS;
            case 5:
                return Distinst.FileSystemType.NTFS;
            default:
                return Distinst.FileSystemType.NONE;
        }
    }

    private string get_mount () {
        switch (use_as.active) {
            case 0:
                return "/";
            case 1:
                return "/home";
            case 2:
                if (Distinst.bootloader_detect () == Distinst.PartitionTable.GPT) {
                    return "/boot/efi";
                } else {
                    return "/boot";
                }
            case 3:
                return "swap";
            default:
                return custom.get_text ();
        }
    }

    private bool values_ready () {
        return use_partition.active && (!custom_set () || custom_valid ());
    }

    private bool custom_set () {
        return use_as.get_active () == 4;
    }

    private bool custom_valid () {
        return custom.get_text ().has_prefix ("/");
    }
 }
