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

public class Installer.PartitioningView : AbstractInstallerView {
    private Gtk.Button next_button;
    private Gtk.Button modify_partitions_button;
    private Gtk.Box disk_list;
    private Gtk.Stack load_stack;
    private string required_description;

    public Gee.ArrayList<Installer.Mount> mounts;
    public Gee.ArrayList<InstallerDaemon.LuksCredentials?> luks;

    public static uint64 minimum_disk_size;

    public PartitioningView (uint64 size) {
        minimum_disk_size = size;
        Object (cancellable: false);
    }

    [Flags]
    public enum Defined {
        ROOT,
        EFI
    }

    const uint64 REQUIRED_EFI_SECTORS = 524288;

    construct {
        mounts = new Gee.ArrayList<Installer.Mount> ();
        luks = new Gee.ArrayList<InstallerDaemon.LuksCredentials?> ();

        add_css_class ("partition");
        title = _("Select Partitions");

        var title_label = new Gtk.Label (title);

        var format_row = new DescriptionRow (
            _("Selecting “Format” will erase <i>all</i> data on the selected partition."),
            "dialog-warning-symbolic",
            "orange"
        );

        var bootloader = Daemon.get_default ().bootloader_detect ();
        switch (bootloader) {
            case MSDOS:
                // Device is in BIOS mode, so we just require a root partition
                required_description = _("You must at least select a <b>Root (/)</b> partition.");
                break;
            case GPT:
                // Device is in EFI mode, so we also require a boot partition
                required_description = _("You must at least select a <b>Root (/)</b> partition and an optional <b>Boot (/boot/efi)</b> partition.");
                break;
        }

        var required_row = new DescriptionRow (
            required_description,
            "emblem-system-symbolic",
            "orange"
        );

        var recommended_row = new DescriptionRow (
            _("It is also recommended to select a <b>Swap</b> partition."),
            "media-memory-symbolic",
            "blue"
        );

        var description_box = new Gtk.Box (VERTICAL, 12) {
            margin_end = 12,
            margin_start = 12
        };
        description_box.append (format_row);
        description_box.append (required_row);
        description_box.append (recommended_row);

        disk_list = new Gtk.Box (VERTICAL, 24) {
            margin_end = 12,
            margin_start = 12,
            valign = CENTER
        };

        var disk_scroller = new Gtk.ScrolledWindow () {
            child = disk_list,
            hexpand = true,
            hscrollbar_policy = NEVER,
            propagate_natural_height = true
        };

        var load_spinner = new Gtk.Spinner () {
            halign = CENTER,
            valign = CENTER
        };
        load_spinner.start ();

        var load_label = new Gtk.Label (_("Getting the current configuration…"));
        load_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        var load_box = new Gtk.Box (VERTICAL, 12) {
            hexpand = true,
            vexpand = true,
            valign = CENTER,
            halign = CENTER
        };
        load_box.append (load_spinner);
        load_box.append (load_label);

        load_stack = new Gtk.Stack () {
            transition_type = CROSSFADE
        };
        load_stack.add_named (load_box, "loading");
        load_stack.add_named (disk_scroller, "disk");

        title_area.append (title_label);

        content_area.valign = CENTER;
        content_area.append (description_box);
        content_area.append (load_stack);

        load_disks.begin ();

        modify_partitions_button = new Gtk.Button.with_label (_("Modify Partitions…"));
        modify_partitions_button.clicked.connect (() => open_partition_editor ());

        var back_button = new Gtk.Button.with_label (_("Back")) {
            action_name = "win.back"
        };

        next_button = new Gtk.Button.with_label (_("Next"));
        next_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.sensitive = false;

        action_box_start.append (modify_partitions_button);
        action_box_end.append (back_button);
        action_box_end.append (next_button);

        next_button.clicked.connect (() => next_step ());
    }

    private async void load_disks () {
        load_stack.set_visible_child_name ("loading");

        InstallerDaemon.DiskInfo? disks = null;
        try {
            if (!Installer.App.test_mode) {
                disks = yield Daemon.get_default ().get_disks (true);
            } else {
                disks = get_test_diskinfo ();
            }
        } catch (Error e) {
            critical ("Unable to get disks: %s", e.message);
            load_stack.set_visible_child_name ("disk");
            return;
        }

        foreach (unowned InstallerDaemon.Disk disk in disks.physical_disks) {
            disk_list.append (get_disk_bar (disk, false));
        }

        foreach (unowned InstallerDaemon.Disk disk in disks.logical_disks) {
            disk_list.append (get_disk_bar (disk, true));
        }

        load_stack.set_visible_child_name ("disk");
    }

    private void open_partition_editor () {
        try {
            /*
             * FIXME: GParted provides a .desktop file, so we should use
             * GLib.AppInfo. However, we need a better way to listen to
             * partition changes if we do that.
             */
            var gparted = new GLib.Subprocess.newv ({"gparted"}, GLib.SubprocessFlags.NONE);
            gparted.wait ();
        } catch (GLib.Error error) {
            critical ("could not execute gparted");
        }

        reset_view ();
    }

    public void reset_view () {
        debug ("Resetting partitioning view");

        while (disk_list.get_first_child () != null) {
            disk_list.remove (disk_list.get_first_child ());
        }

        mounts.clear ();
        luks.clear ();
        next_button.sensitive = false;
        load_disks.begin ();
    }

    private DiskBar get_disk_bar (InstallerDaemon.Disk disk, bool lvm) {
        var partitions = new Gee.ArrayList<PartitionBlock> ();
        foreach (unowned InstallerDaemon.Partition part in disk.partitions) {
            var partition = new PartitionBlock (part);

            if (part.filesystem == LUKS) {
                partition.menu = new DecryptMenu (part.device_path);
                ((DecryptMenu) partition.menu).decrypted.connect (on_partition_decrypted);
            } else {
                partition.menu = new PartitionMenu (part.device_path, disk.device_path, part.filesystem, lvm, this.set_mount, this.unset_mount, this.mount_is_set, partition);
            }

            partitions.add (partition);
        }

        return new DiskBar (disk, (owned) partitions);
    }

    private void validate_status () {
        uint8 flags = 0;
        uint8 required = Defined.ROOT;

        var bootloader = Daemon.get_default ().bootloader_detect ();
        switch (bootloader) {
            case MSDOS:
                break;
            case GPT:
                break;
        }

        string layout_debug = "";
        foreach (Mount m in mounts) {
            layout_debug +=
                "  %s : %s : %s : %s: format? %s\n".printf (
                m.parent_disk,
                m.partition_path,
                m.mount_point,
                m.filesystem.to_string (),
                m.should_format () ? "true" : "false"
            );

            if (m.mount_point == "/") {
                flags |= Defined.ROOT;
            } else if (m.mount_point == "/boot/efi") {
                flags |= Defined.EFI;
            }
        }

        debug ("DEBUG: Current Layout:\n" + layout_debug);
        next_button.sensitive = required in flags;
    }

    private void on_partition_decrypted (InstallerDaemon.LuksCredentials credentials) {
        luks.add (credentials);
        Daemon.get_default ().get_logical_device.begin (credentials.pv, (obj, res) => {
            try {
                var disk = ((Daemon)obj).get_logical_device.end (res);
                disk_list.append (get_disk_bar (disk, true));
            } catch (Error e) {
                critical ("Unable to get logical device: %s", e.message);
            }
        });
    }

    private void set_mount (Mount mount) throws GLib.Error {
        unset_mount_point (mount);

        if (mount.mount_point == "/boot/efi") {
            if (!mount.is_valid_boot_mount ()) {
                throw new GLib.IOError.FAILED (_("EFI partition has the wrong file system"));
            } else if (mount.sectors < REQUIRED_EFI_SECTORS) {
                throw new GLib.IOError.FAILED (_("EFI partition is too small"));
            }
        } else if (mount.mount_point == "/" && !mount.is_valid_root_mount ()) {
            throw new GLib.IOError.FAILED (_("Invalid file system for root"));
        } else if (mount.mount_point == "/home" && !mount.is_valid_root_mount ()) {
            throw new GLib.IOError.FAILED (_("Invalid file system for home"));
        }

        for (int i = 0; i < mounts.size; i++) {
            if (mounts[i].partition_path == mount.partition_path) {
                mounts[i] = mount;
                validate_status ();
                return;
            }
        }

        validate_status ();
        mounts.add (mount);
        validate_status ();
    }

    private bool mount_is_set (string mount_point) {
        return mounts.any_match ((m) => m.mount_point == mount_point);
    }

    private void unset_mount (string partition) {
        remove_mount_by_partition (partition);
        validate_status ();
    }

    private void remove_mount_by_partition (string partition) {
        for (int i = 0; i < mounts.size; i++) {
            if (mounts[i].partition_path == partition) {
                swap_remove_mount (mounts, i);
                break;
            }
        }
    }

    private void unset_mount_point (Mount src) {
        for (int i = 0; i < mounts.size; i++) {
            var m = mounts[i];
            if (m.mount_point == src.mount_point && m.partition_path != src.partition_path) {
                m.menu.unset ();
                swap_remove_mount (mounts, i);
                break;
            }
        }
    }

    private Mount swap_remove_mount (Gee.ArrayList<Mount> array, int index) {
        array[index] = array[array.size - 1];
        return array.remove_at (array.size - 1);
    }

    private InstallerDaemon.DiskInfo get_test_diskinfo () {
        InstallerDaemon.Disk[] physical_disks = {};
        InstallerDaemon.Disk[] logical_disks = {};

        InstallerDaemon.Partition[] partitions = {};

        var usage_1 = InstallerDaemon.PartitionUsage () {
            tag = 1,
            value = 30312
        };

        partitions += InstallerDaemon.Partition () {
            device_path = "/dev/nvme0n1p1",
            filesystem = InstallerDaemon.FileSystem.FAT32,
            start_sector = 4096,
            end_sector = 542966,
            sectors_used = usage_1,
            current_lvm_volume_group = ""
        };

        var usage_2 = InstallerDaemon.PartitionUsage () {
            tag = 0,
            value = 0
        };

        partitions += InstallerDaemon.Partition () {
            device_path = "/dev/nvme0n1p2",
            filesystem = InstallerDaemon.FileSystem.LVM,
            start_sector = 542968,
            end_sector = 376769070,
            sectors_used = usage_2,
            current_lvm_volume_group = "data"
        };

        physical_disks += InstallerDaemon.Disk () {
            name = "Samsung SSD 970 EVO 500GB",
            device_path = "/dev/nvme0n1",
            sectors = 976773168,
            sector_size = 512,
            rotational = false,
            removable = false,
            partitions = partitions
        };

        return InstallerDaemon.DiskInfo () {
            physical_disks = physical_disks,
            logical_disks = logical_disks
        };
    }
}
