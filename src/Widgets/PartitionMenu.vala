/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public delegate void SetMount (Installer.Mount mount) throws GLib.Error;

public delegate void UnsetMount (string partition);

public delegate bool MountSetFn (string mount_point);

public class Installer.PartitionMenu : Gtk.Popover {
    public InstallerDaemon.Partition partition { get; construct; }
    public string parent_disk { get; construct; }
    public bool is_lvm { get; construct; }
    // A reference to the parent which owns this menu.
    public PartitionBlock partition_block { get; construct; }

    private bool disable_signals;

    private Granite.SwitchModelButton format_partition;
    private Granite.SwitchModelButton use_partition;
    private Gtk.ComboBoxText type;
    private Gtk.ComboBoxText use_as;
    private Gtk.Entry custom;

    public PartitionMenu (
        InstallerDaemon.Partition partition,
        string parent,
        bool lvm,
        SetMount set_mount,
        UnsetMount unset_mount,
        MountSetFn mount_set,
        PartitionBlock partition_block
    ) {
        Object (
            partition: partition,
            parent_disk: parent,
            is_lvm: lvm,
            partition_block: partition_block
        );

        var boot_partition = (Daemon.get_default ().bootloader_detect () == GPT)
            ? "/boot/efi"
            : "/boot";

        use_partition = new Granite.SwitchModelButton (_("Use Partition"));

        var separator = new Gtk.Separator (HORIZONTAL);

        format_partition = new Granite.SwitchModelButton (_("Format")) {
            description = _("Delete all data and set up a new file system")
        };

        var use_as_label = new Gtk.Label (_("Use as:")) {
            halign = END,
            xalign = 1
        };

        use_as = new Gtk.ComboBoxText () {
            hexpand = true
        };
        use_as.append_text (_("Root (/)"));
        use_as.append_text (_("Home (/home)"));
        use_as.append_text (_("Boot (%s)".printf (boot_partition)));
        use_as.append_text (_("Swap"));
        use_as.append_text (_("Custom"));
        use_as.active = 0;
        use_as.bind_property ("visible", use_as_label, "visible");

        var custom_label = new Gtk.Label (_("Custom:")) {
            halign = END,
            xalign = 1
        };

        custom = new Gtk.Entry ();
        custom.bind_property ("visible", custom_label, "visible");

        var type_label = new Gtk.Label (_("Filesystem:")) {
            halign = END,
            xalign = 1
        };

        var label_size_group = new Gtk.SizeGroup (HORIZONTAL);
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
                if (Daemon.get_default ().bootloader_detect () == Distinst.PartitionTable.GPT) {
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
                if (partition.filesystem == FAT16 || partition.filesystem == FAT32) {
                    if (mount_set (boot_partition)) {
                        select = 4;
                    } else {
                        select = 2;
                    }
                } else if (partition.filesystem == SWAP) {
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
                unset_mount (partition.device_path);
                partition_block.icon = null;
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
        partition_block.icon = null;
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
            ? InstallerDaemon.FileSystem.SWAP
            : get_file_system ();

        string? error = null;
        try {
            set_mount (new Installer.Mount (
                partition.device_path,
                parent_disk,
                mount,
                partition_block.get_partition_size (),
                (format_partition.active ? InstallerDaemon.MountFlags.FORMAT : 0)
                    + (is_lvm ? InstallerDaemon.MountFlags.LVM : 0),
                filesystem,
                this
            ));
        } catch (GLib.Error why) {
            error = why.message;
        }

        partition_block.icon = new ThemedIcon (
            error == null ? "process-completed-symbolic" : "dialog-warning-symbolic"
        );

        if (error != null) {
            partition_block.tooltip_text = error;
        }
    }

    private bool has_same_filesystem () {
        return partition.filesystem == get_file_system ();
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
                if (Daemon.get_default ().bootloader_detect () == Distinst.PartitionTable.GPT) {
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
