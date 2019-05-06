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
    private Distinst.Disks disks;
    private Gtk.Box disk_list;
    private Gtk.SizeGroup label_sizer;
    private string required_description;
    private HelpDialog help_dialog;

    public Gee.ArrayList<Installer.Mount> mounts;
    public Gee.ArrayList<LuksCredentials> luks;

    public static uint64 minimum_disk_size;

    public PartitioningView (uint64 size) {
        minimum_disk_size = size;
        Object (cancellable: true);
    }

    [Flags]
    public enum Defined {
        ROOT,
        EFI
    }

    const uint64 REQUIRED_EFI_SECTORS = 500 * 1000 * 1000 / 512;

    construct {
        mounts = new Gee.ArrayList<Installer.Mount> ();
        luks = new Gee.ArrayList<LuksCredentials> ();
        margin = 12;

        var base_description = _("Select which partitions to use across all drives. <b>Selecting \"Format\" will erase ALL data on the selected partition.</b>");

        var bootloader = Distinst.bootloader_detect ();
        switch (bootloader) {
            case Distinst.PartitionTable.MSDOS:
                // Device is in BIOS mode, so we just require a root partition
                required_description = _("You must at least select a <b>Root (/)</b> partition.");
                break;
            case Distinst.PartitionTable.GPT:
                // Device is in EFI mode, so we also require a boot partition
                required_description = _("You must at least select a <b>Root (/)</b> partition, plus a <b>Boot (/boot/efi)</b> partition that is at least 500 MiB and on a GPT disk.");
                break;
        }

        var recommended_description = _("It is also recommended to select a <b>Swap</b> partition.");

        var full_description = "%s %s %s".printf (
            base_description,
            required_description,
            recommended_description
        );

        var description = new Gtk.Label (full_description);
        description.margin_bottom = description.margin_bottom = 24;
        description.max_width_chars = 72;
        description.use_markup = true;
        description.wrap = true;

        disk_list = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        disk_list.valign = Gtk.Align.START;
        disk_list.margin = 6;
        disk_list.margin_end = 12;

        var disk_scroller = new Gtk.ScrolledWindow (null, null);
        disk_scroller.hexpand = true;
        disk_scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
        disk_scroller.add (disk_list);

        content_area.attach (disk_scroller, 0, 0);
        content_area.attach (description, 0, 1);

        load_disks ();

        var help_button = new Gtk.Button.with_label (_("?"));
        help_button.tooltip_text = _("Help with Dual Booting");
        help_button.get_style_context ().add_class ("circular");

        modify_partitions_button = new Gtk.Button.with_label (_("Modify Partitions…"));

        var back_button = new Gtk.Button.with_label (_("Back"));

        next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;

        action_area.homogeneous = false;

        action_area.add (help_button);
        action_area.set_child_secondary (help_button, true);
        action_area.set_child_non_homogeneous (help_button, true);

        action_area.add (modify_partitions_button);
        action_area.set_child_secondary (modify_partitions_button, true);
        action_area.set_child_non_homogeneous (modify_partitions_button, true);

        action_area.add (back_button);
        action_area.add (next_button);

        // Display a help dialog when the help_button is clicked.
        //
        // Ensures that only one instance of the help dialog is active at
        // given time.
        var dialog_open = false;
        help_button.clicked.connect (() => {
            if (!dialog_open) {
                dialog_open = true;
                help_dialog = new HelpDialog ();
                help_dialog.transient_for = (Gtk.Window) get_toplevel ();
                help_dialog.delete_event.connect (() => {
                    dialog_open = false;
                    return false;
                });
            }
        });

        // Opens GParted when the modify_partitions_button is clicked.
        //
        // The extra logic here will prevent the subprocess from opening
        // multiple times in succession when this button is clicked multiple
        // times.
        modify_partitions_button.clicked.connect (() => {
            if (modify_partitions_button.sensitive) {
                modify_partitions_button.sensitive = false;
                Idle.add (() => {
                    open_partition_editor ();
                    Idle.add (() => {
                        modify_partitions_button.sensitive = true;
                        return false;
                    });
                    return false;
                });
            }
        });

        back_button.clicked.connect (() => {
            Distinst.deactivate_logical_devices ();
            ((Gtk.Stack) get_parent ()).visible_child = previous_view;
        });

        next_button.clicked.connect (() => next_step ());
        show_all ();
    }

    private void load_disks () {
        disks = Distinst.Disks.probe ();
        disks.initialize_volume_groups ();
        label_sizer = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);

        foreach (unowned Distinst.Disk disk in disks.list ()) {
            if (disk.is_read_only ()) {
                continue;
            }

            // Skip root disk or live disk
            if (!InstallOptions.get_default ().has_recovery () && (disk.contains_mount ("/", disks) || disk.contains_mount ("/cdrom", disks))) {
                continue;
            }

            var sector_size = disk.get_sector_size ();
            var size = disk.get_sectors () * sector_size;

            string path = Utils.string_from_utf8 (disk.get_device_path ());
            string model = Utils.string_from_utf8 (disk.get_model ());

            var partitions = new Gee.ArrayList<PartitionBar> ();
            foreach (unowned Distinst.Partition part in disk.list_partitions ()) {
                var partition = new PartitionBar (part, path, sector_size, false, this.set_mount, this.unset_mount, this.mount_is_set, this.decrypt);
                partitions.add (partition);
            }

            var disk_bar = new DiskBar (model, path, size, (owned) partitions);
            label_sizer.add_widget (disk_bar.label);
            disk_list.pack_start (disk_bar);
        }

        foreach (unowned Distinst.LvmDevice disk in disks.list_logical ()) {
            add_logical_disk (disk);
        }

        disk_list.show_all ();
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
        load_disks ();
    }

    private void add_logical_disk (Distinst.LvmDevice disk) {
        var sector_size = disk.get_sector_size ();
        var size = disk.get_sectors () * sector_size;

        string path = Utils.string_from_utf8 (disk.get_device_path ());
        string model = Utils.string_from_utf8 (disk.get_model ());

        var partitions = new Gee.ArrayList<PartitionBar> ();

        unowned Distinst.Partition? poss_part = disk.get_encrypted_file_system ();
        if (poss_part != null) {
            partitions.add (new PartitionBar (poss_part, path, sector_size, true, this.set_mount, this.unset_mount, this.mount_is_set, this.decrypt));
        } else {
            foreach (unowned Distinst.Partition part in disk.list_partitions ()) {
                var partition = new PartitionBar (part, path, sector_size, true, this.set_mount, this.unset_mount, this.mount_is_set, this.decrypt);
                partitions.add (partition);
            }
        }

        var disk_bar = new DiskBar (model, path, size, (owned) partitions);
        label_sizer.add_widget (disk_bar.label);
        disk_list.pack_start (disk_bar);
    }

    private void validate_status () {
        uint8 flags = 0;
        uint8 required = Defined.ROOT;

        var bootloader = Distinst.bootloader_detect ();
        switch (bootloader) {
            case Distinst.PartitionTable.MSDOS:
                break;
            case Distinst.PartitionTable.GPT:
                required |= Defined.EFI;
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

        stderr.printf ("DEBUG: Current Layout:\n" + layout_debug);
        next_button.sensitive = required in flags;
    }

    private bool decrypt (string device, string pv, string password, DecryptMenu menu) {
        try {
            Utils.decrypt_partition (disks, device, pv, password);
        } catch (Error e) {
            menu.set_error (e.message);
            return false;
        }

        unowned Distinst.LvmDevice disk = disks.get_logical_device_within_pv (pv);
        add_logical_disk (disk);
        luks.add (new LuksCredentials (device, pv, password));
        return true;
    }

    private void set_mount (Mount mount) throws GLib.Error {
        unset_mount_point (mount);

        string? error = null;

        if (mount.mount_point == "/boot/efi") {
            unowned Distinst.Disk? disk = disks.get_physical_device (mount.parent_disk);
            if (disk == null) {
                throw new GLib.IOError.FAILED (_("Cannot find parent disk of EFI partition"));
            } else if (disk.get_partition_table () != Distinst.PartitionTable.GPT) {
                throw new GLib.IOError.FAILED (_("EFI partition is not on a GPT disk"));
            } else if (!mount.is_valid_boot_mount ()) {
                throw new GLib.IOError.FAILED (_("EFI partition has the wrong file system"));
            } else if (mount.sectors < REQUIRED_EFI_SECTORS) {
                error = _("EFI partition is too small");
            }
        } else if (mount.mount_point == "/" && !mount.is_valid_root_mount ()) {
            error = _("Invalid file system for root");
        } else if (mount.mount_point == "/home" && !mount.is_valid_root_mount ()) {
            error = _("Invalid file system for home");
        }

        if (error != null) {
            throw new GLib.IOError.FAILED (error);
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
