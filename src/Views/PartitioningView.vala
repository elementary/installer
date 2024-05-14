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
    public signal void next_step ();

    private Gtk.Button next_button;
    private Gtk.Button modify_partitions_button;
    private Gtk.Grid disk_list;
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

        var base_description = _("Select which partitions to use across all drives. <b>Selecting \"Format\" will erase ALL data on the selected partition.</b>");

        var bootloader = Daemon.get_default ().bootloader_detect ();
        switch (bootloader) {
            case Distinst.PartitionTable.MSDOS:
                // Device is in BIOS mode, so we just require a root partition
                required_description = _("You must at least select a <b>Root (/)</b> partition.");
                break;
            case Distinst.PartitionTable.GPT:
                // Device is in EFI mode, so we also require a boot partition
                required_description = _("You must at least select a <b>Root (/)</b> partition and an optional <b>Boot (/boot/efi)</b> partition.");
                break;
        }

        var recommended_description = _("It is also recommended to select a <b>Swap</b> partition.");

        var full_description = "%s %s %s".printf (
            base_description,
            required_description,
            recommended_description
        );

        var description = new Gtk.Label (full_description);
        description.max_width_chars = 72;
        description.use_markup = true;
        description.wrap = true;

        disk_list = new Gtk.Grid () {
            row_spacing = 24,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.CENTER
        };

        var disk_scroller = new Gtk.ScrolledWindow ();
        disk_scroller.hexpand = true;
        disk_scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
        disk_scroller.add (disk_list);

        var load_spinner = new Gtk.Spinner ();
        load_spinner.halign = Gtk.Align.CENTER;
        load_spinner.valign = Gtk.Align.CENTER;
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

        load_stack = new Gtk.Stack ();
        load_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        load_stack.add_named (load_box, "loading");
        load_stack.add_named (disk_scroller, "disk");

        content_area.margin_top = 12;
        content_area.margin_end = 12;
        content_area.margin_bottom = 12;
        content_area.margin_start = 12;
        content_area.attach (description, 0, 0);
        content_area.attach (load_stack, 0, 1);

        load_disks.begin ();

        modify_partitions_button = new Gtk.Button.with_label (_("Modify Partitions…"));
        modify_partitions_button.clicked.connect (() => open_partition_editor ());

        var back_button = new Gtk.Button.with_label (_("Back"));

        next_button = new Gtk.Button.with_label (_("Next"));
        next_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.sensitive = false;

        action_box_start.add (modify_partitions_button);
        action_box_end.append (back_button);
        action_box_end.append (next_button);

        back_button.clicked.connect (() => ((Adw.Leaflet) get_parent ()).navigate (Hdy.NavigationDirection.BACK));
        next_button.clicked.connect (() => next_step ());
    }

    private async void load_disks () {
        load_stack.set_visible_child_name ("loading");

        InstallerDaemon.DiskInfo? disks = null;
        try {
            disks = yield Daemon.get_default ().get_disks (true);
        } catch (Error e) {
            critical ("Unable to get disks: %s", e.message);
            load_stack.set_visible_child_name ("disk");
            return;
        }

        foreach (unowned InstallerDaemon.Disk disk in disks.physical_disks) {
            var sector_size = disk.sector_size;
            var size = disk.sectors * sector_size;

            unowned string path = disk.device_path;

            var partitions = new Gee.ArrayList<PartitionBar> ();
            foreach (unowned InstallerDaemon.Partition part in disk.partitions) {
                var partition = new PartitionBar (part, path, sector_size, false, this.set_mount, this.unset_mount, this.mount_is_set);
                partition.decrypted.connect (on_partition_decrypted);
                partitions.add (partition);
            }

            var disk_bar = new DiskBar (disk.name, path, size, (owned) partitions);
            disk_list.add (disk_bar);
        }

        foreach (unowned InstallerDaemon.Disk disk in disks.logical_disks) {
            add_logical_disk (disk);
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
        disk_list.get_children ().foreach ((child) => child.destroy ());
        mounts.clear ();
        luks.clear ();
        next_button.sensitive = false;
        load_disks.begin ();
    }

    private void add_logical_disk (InstallerDaemon.Disk disk) {
        var sector_size = disk.sector_size;
        var size = disk.sectors * sector_size;

        unowned string path = disk.device_path;

        var partitions = new Gee.ArrayList<PartitionBar> ();
        foreach (unowned InstallerDaemon.Partition part in disk.partitions) {
            var partition = new PartitionBar (part, path, sector_size, true, this.set_mount, this.unset_mount, this.mount_is_set);
            partition.decrypted.connect (on_partition_decrypted);
            partitions.add (partition);
        }

        var disk_bar = new DiskBar (disk.name, path, size, (owned) partitions);
        disk_list.add (disk_bar);
    }

    private void validate_status () {
        uint8 flags = 0;
        uint8 required = Defined.ROOT;

        var bootloader = Daemon.get_default ().bootloader_detect ();
        switch (bootloader) {
            case Distinst.PartitionTable.MSDOS:
                break;
            case Distinst.PartitionTable.GPT:
                break;
        }

        string layout_debug = "";
        foreach (Mount m in mounts) {
            layout_debug +=
                "  %s : %s : %s : %s: format? %s\n".printf (
                m.parent_disk,
                m.partition_path,
                m.mount_point,
                Distinst.strfilesys (m.filesystem),
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
                add_logical_disk (disk);
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
}
