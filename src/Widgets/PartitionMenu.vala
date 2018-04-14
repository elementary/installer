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

public delegate void SetMount (Installer.Mount mount);

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

        var use_partition_label = new Gtk.Label ("Use partition:");
        use_partition_label.halign = Gtk.Align.END;
        use_partition_label.hexpand = true;
        use_partition_label.xalign = 1;
        label_size_group.add_widget (format_label);

        use_partition = new Gtk.Switch ();
        use_partition.halign = Gtk.Align.START;
        use_partition.hexpand = false;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        format_label = new Gtk.Label ("Format:");
        format_label.halign = Gtk.Align.END;
        format_label.hexpand = true;
        format_label.xalign = 1;
        label_size_group.add_widget (format_label);

        format_partition = new Gtk.Switch ();
        format_partition.halign = Gtk.Align.START;
        format_partition.hexpand = false;

        var use_as_label = new Gtk.Label ("Use as:");
        use_as_label.halign = Gtk.Align.END;
        use_as_label.hexpand = true;
        use_as_label.xalign = 1;
        label_size_group.add_widget (use_as_label);

        use_as = new Gtk.ComboBoxText ();
        use_as.append_text (_("Root (/)"));
        use_as.append_text (_("Home (/home)"));
        use_as.append_text (_("Boot (%s)".printf (boot_partition)));
        use_as.append_text (_("Swap"));
        use_as.append_text (_("Custom"));
        use_as.set_active (0);

        custom_label = new Gtk.Label ("Custom:");
        custom_label.halign = Gtk.Align.END;
        custom_label.hexpand = true;
        custom_label.xalign = 1;
        label_size_group.add_widget (custom_label);

        custom = new Gtk.Entry ();

        type_label = new Gtk.Label ("Type:");
        type_label.halign = Gtk.Align.END;
        type_label.hexpand = true;
        type_label.xalign = 1;
        label_size_group.add_widget (type_label);

        type = new Gtk.ComboBoxText ();
        type.append_text (_("Default (ext4)"));
        type.append_text ("fat16");
        type.append_text ("fat32");
        type.append_text ("btrfs");
        type.append_text ("xfs");
        type.append_text ("ntfs");
        type.set_active (0);
        
        var top_controls = new Gtk.Grid ();
        top_controls.column_spacing = 12;
        top_controls.row_spacing = 6;
        top_controls.margin = 6;

        top_controls.attach (use_partition_label, 0, 0, 1, 1);
        top_controls.attach (use_partition,       1, 0, 1, 1);

        var bottom_controls = new Gtk.Grid ();
        bottom_controls.column_spacing = 12;
        bottom_controls.row_spacing = 6;
        bottom_controls.margin = 6;

        bottom_controls.attach (format_label, 0, 1);
        bottom_controls.attach (use_as_label, 0, 2);
        bottom_controls.attach (custom_label, 0, 3);
        bottom_controls.attach (type_label,   0, 4);

        bottom_controls.attach (format_partition, 1, 1);
        bottom_controls.attach (use_as,           1, 2);
        bottom_controls.attach (custom,           1, 3);
        bottom_controls.attach (type,             1, 4);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;

        var revealer = new Gtk.Revealer ();
        // revealer.add (separator);
        revealer.add (bottom_controls);

        grid.attach (top_controls, 0, 0, 1, 1);
        grid.attach (revealer,     0, 1, 1, 1);

        this.add (grid);
        grid.show_all ();

        custom.set_visible (false);
        custom_label.set_visible (false);
        format_partition.set_visible (false);
        format_label.set_visible (false);

        format_partition.notify["active"].connect (() => {
            if (!disable_signals) {
                check_values (set_mount);
            }
        });

        use_as.changed.connect (() => {
            if (disable_signals) {
                return;
            }

            var active = use_as.get_active ();
            bool visible = active == 4;

            custom.set_visible (visible);
            custom_label.set_visible (visible);

            if (active == 2) {
                if (Distinst.bootloader_detect () == Distinst.PartitionTable.GPT) {
                    type.set_active (2);
                } else {
                    type.set_active (0);
                }
                type_label.set_visible (true);
                type.set_visible (true);
                type.set_sensitive (false);
                format_label.set_visible (true);
                format_partition.set_visible (true);
            } else if (active == 3) {
                format_label.set_visible (false);
                format_partition.set_visible (false);
                disable_signals = true;
                format_partition.active = true;
                disable_signals = false;
                type_label.set_visible (false);
                type.set_visible (false);
            } else {
                type_label.set_visible (true);
                type.set_visible (true);
                type.set_sensitive (true);
                format_label.set_visible (true);
                format_partition.set_visible (true);
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
                use_as.set_active (
                    (fs == Distinst.FileSystemType.FAT16 || fs == Distinst.FileSystemType.FAT32)
                        ? mount_set (boot_partition) ? 4 : 2
                        : fs == Distinst.FileSystemType.SWAP
                            ? 3
                            : mount_set ("/")
                                ? mount_set ("/home" ) ? 4 : 1
                                : 0
                );
                update_values (set_mount);
            } else {
                unset_mount (partition_path);
                partition_bar.container.get_children ().foreach ((c) => c.destroy ());
            }

            revealer.set_reveal_child (use_partition.active);
            format_partition.set_visible (use_partition.active);
            format_label.set_visible (use_partition.active);
        });
    }

    public void unset () {
        disable_signals = true;
        use_partition.active = false;
        use_as.set_active (0);
        type.set_active (0);
        type.set_sensitive (true);
        type.set_visible (true);
        type_label.set_visible (true);
        custom.set_visible (false);
        custom_label.set_visible (false);
        disable_signals = false;
        partition_bar.container.get_children ().foreach ((c) => c.destroy ());
    }

    private void set_format_sensitivity () {
        bool is_sensitive = has_same_filesystem ();
        format_partition.active = !is_sensitive;
        format_partition.set_sensitive (is_sensitive);
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

        set_mount (new Installer.Mount (
            partition_path,
            parent_disk,
            mount,
            (format_partition.active ? Mount.FORMAT : 0) + (is_lvm ? Mount.LVM : 0),
            filesystem,
            this
        ));

        var mount_icon = new Gtk.Image.from_icon_name (
            "process-completed-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        );
        mount_icon.set_halign (Gtk.Align.END);
        mount_icon.set_valign (Gtk.Align.END);
        mount_icon.margin = 2;
        partition_bar.container.get_children ().foreach((c) => c.destroy ());
        partition_bar.container.pack_start(mount_icon, true, true, 0);
        partition_bar.container.show_all ();
    }

    private bool has_same_filesystem () {
        return original_filesystem == get_file_system ();
    }

    private Distinst.FileSystemType get_file_system () {
        switch (type.get_active ()) {
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
        switch (use_as.get_active ()) {
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
        return use_as.get_active() == 4;
    }

    private bool custom_valid () {
        return custom.get_text ().has_prefix ("/");
    }
 }
