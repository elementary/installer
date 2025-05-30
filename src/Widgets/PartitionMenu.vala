/*-
 * Copyright 2018-2021 elementary, inc. (https://elementary.io)
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

public delegate void SetMount (Installer.Mount mount) throws GLib.Error;

public delegate void UnsetMount (string partition);

public delegate bool MountSetFn (string mount_point);

public class Installer.PartitionMenu : Gtk.Popover {
    private bool disable_signals;
    private bool is_lvm;
    private string parent_disk;
    private string partition_path;
    private InstallerDaemon.FileSystem original_filesystem;

    private Granite.SwitchModelButton format_partition;
    private Granite.SwitchModelButton use_partition;
    private Gtk.ComboBoxText type;
    private Gtk.ComboBoxText use_as;
    private Gtk.Entry custom;
    private Gtk.Label custom_label;
    private Gtk.Label type_label;
    // A reference to the parent which owns this menu.
    private PartitionBlock partition_bar;

    public PartitionMenu (string path, string parent, InstallerDaemon.FileSystem fs,
                          bool lvm, SetMount set_mount, UnsetMount unset_mount,
                          MountSetFn mount_set, PartitionBlock partition_bar) {
        this.partition_bar = partition_bar;
        original_filesystem = fs;
        is_lvm = lvm;
        partition_path = path;
        parent_disk = parent;

        string boot_partition = (Daemon.get_default ().bootloader_detect () == InstallerDaemon.PartitionTable.GPT)
            ? "/boot/efi"
            : "/boot";

        use_partition = new Granite.SwitchModelButton (_("Use Partition"));

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        format_partition = new Granite.SwitchModelButton (_("Format")) {
            description = _("Delete all data and set up a new file system")
        };

        var use_as_label = new Gtk.Label (_("Use as:"));
        use_as_label.halign = Gtk.Align.END;
        use_as_label.xalign = 1;

        use_as = new Gtk.ComboBoxText () {
            hexpand = true
        };
        use_as.append_text (_("Root (/)"));
        use_as.append_text (_("Home (/home)"));
        use_as.append_text (_("Boot (%s)").printf (boot_partition));
        use_as.append_text (_("Swap"));
        use_as.append_text (_("Custom"));
        use_as.active = 0;
        use_as.bind_property ("visible", use_as_label, "visible");

        custom_label = new Gtk.Label (_("Custom:"));
        custom_label.halign = Gtk.Align.END;
        custom_label.xalign = 1;

        custom = new Gtk.Entry ();
        custom.bind_property ("visible", custom_label, "visible");

        type_label = new Gtk.Label (_("Filesystem:"));
        type_label.halign = Gtk.Align.END;
        type_label.xalign = 1;

        var label_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        label_size_group.add_widget (use_as_label);
        label_size_group.add_widget (custom_label);
        label_size_group.add_widget (type_label);

        type = new Gtk.ComboBoxText () {
            hexpand = true
        };
        type.append_text (_("Default (ext4)"));
        type.append_text ("fat16");
        type.append_text ("fat32");
        type.append_text ("btrfs");
        type.append_text ("xfs");
        type.append_text ("ntfs");
        type.active = 0;
        type.bind_property ("visible", type_label, "visible");

        var bottom_controls = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6,
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 9,
            margin_start = 12
        };
        bottom_controls.attach (use_as_label, 0, 2);
        bottom_controls.attach (use_as, 1, 2);
        bottom_controls.attach (custom_label, 0, 3);
        bottom_controls.attach (custom, 1, 3);
        bottom_controls.attach (type_label, 0, 4);
        bottom_controls.attach (type, 1, 4);

        var bottom_grid = new Gtk.Grid () {
            row_spacing = 3
        };
        bottom_grid.attach (format_partition, 0, 0);
        bottom_grid.attach (separator, 0, 1);
        bottom_grid.attach (bottom_controls, 0, 2);

        var bottom_revealer = new Gtk.Revealer () {
            child = bottom_grid
        };

        var grid = new Gtk.Grid () {
            margin_top = 3,
            margin_bottom = 3
        };
        grid.attach (use_partition, 0, 0);
        grid.attach (bottom_revealer, 0, 1);

        child = grid;

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
                if (Daemon.get_default ().bootloader_detect () == InstallerDaemon.PartitionTable.GPT) {
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
                if (fs == InstallerDaemon.FileSystem.FAT16 || fs == InstallerDaemon.FileSystem.FAT32) {
                    if (mount_set (boot_partition)) {
                        select = 4;
                    } else {
                        select = 2;
                    }
                } else if (fs == InstallerDaemon.FileSystem.SWAP) {
                    select = 3;
                } else if (mount_set ("/")) {
                    if (mount_set ("/home" )) {
                        select = 4;
                    } else {
                        select = 1;
                    }
                }
                use_as.set_active (select);
                check_values (set_mount);
            } else {
                unset_mount (partition_path);
                partition_bar.icon = null;
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
        partition_bar.icon = null;
    }

    private void set_format_sensitivity () {
        bool is_sensitive = has_same_filesystem ();
        format_partition.active = !is_sensitive;
        format_partition.sensitive = is_sensitive;
    }

    private void check_values (SetMount set_mount) {
        if (!use_partition.active) {
            partition_bar.icon = null;
            partition_bar.tooltip_text = null;
            return;
        }

        if (use_as.active == 4 && !custom.text.has_prefix ("/")) {
            partition_bar.icon = new ThemedIcon ("dialog-warning-symbolic");
            partition_bar.tooltip_text = _("Custom value must begin with /");
            return;
        }

        var mount = get_mount ();
        var filesystem = mount == "swap" ? InstallerDaemon.FileSystem.SWAP : get_file_system ();

        try {
            set_mount (new Installer.Mount (
                partition_path,
                parent_disk,
                mount,
                partition_bar.get_partition_size_in_sectors (),
                (format_partition.active ? InstallerDaemon.MountFlags.FORMAT : 0)
                    + (is_lvm ? InstallerDaemon.MountFlags.LVM : 0),
                filesystem,
                this
            ));

            partition_bar.icon = new ThemedIcon ("process-completed-symbolic");
            partition_bar.tooltip_text = null;
        } catch (GLib.Error e) {
            partition_bar.icon = new ThemedIcon ("dialog-warning-symbolic");
            partition_bar.tooltip_text = e.message;
        }
    }

    private bool has_same_filesystem () {
        return original_filesystem == get_file_system ();
    }

    private InstallerDaemon.FileSystem get_file_system () {
        switch (type.active) {
            case 0:
                return InstallerDaemon.FileSystem.EXT4;
            case 1:
                return InstallerDaemon.FileSystem.FAT16;
            case 2:
                return InstallerDaemon.FileSystem.FAT32;
            case 3:
                return InstallerDaemon.FileSystem.BTRFS;
            case 4:
                return InstallerDaemon.FileSystem.XFS;
            case 5:
                return InstallerDaemon.FileSystem.NTFS;
            default:
                return InstallerDaemon.FileSystem.NONE;
        }
    }

    private string get_mount () {
        switch (use_as.active) {
            case 0:
                return "/";
            case 1:
                return "/home";
            case 2:
                if (Daemon.get_default ().bootloader_detect () == InstallerDaemon.PartitionTable.GPT) {
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
 }
