// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
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
 */

public class ProgressView : AbstractInstallerView {
    public signal void on_success ();
    public signal void on_error ();

    private Gee.ArrayList<Installer.Mount>? disk_config;

    private double prev_upper_adj = 0;
    private Gtk.ScrolledWindow terminal_output;
    public Gtk.TextView terminal_view { get; construct; }
    private Gtk.ProgressBar progressbar;
    private Gtk.Label progressbar_label;
    private const int NUM_STEP = 5;

    public ProgressView (Gee.ArrayList<Installer.Mount>? mounts) {
        if (mounts == null) {
            stderr.printf ("mounts is null\n");
        }
        this.disk_config = mounts;
    }

    construct {
        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo";
        logo.pixel_size = 128;
        logo.get_style_context ().add_class ("logo");

        unowned LogHelper log_helper = LogHelper.get_default ();
        terminal_view = new Gtk.TextView.with_buffer (log_helper.buffer);
        terminal_view.bottom_margin = terminal_view.top_margin = terminal_view.left_margin = terminal_view.right_margin = 12;
        terminal_view.editable = false;
        terminal_view.cursor_visible = true;
        terminal_view.monospace = true;
        terminal_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        terminal_view.get_style_context ().add_class ("terminal");

        terminal_output = new Gtk.ScrolledWindow (null, null);
        terminal_output.hscrollbar_policy = Gtk.PolicyType.NEVER;
        terminal_output.expand = true;
        terminal_output.add (terminal_view);

        var artwork = new Gtk.Grid ();
        artwork.get_style_context().add_class("progress");
        artwork.get_style_context().add_class("artwork");
        artwork.vexpand = true;

        var logo_stack = new Gtk.Stack ();
        logo_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        logo_stack.add (artwork);
        logo_stack.add (terminal_output);

        var terminal_button = new Gtk.ToggleButton ();
        terminal_button.halign = Gtk.Align.END;
        terminal_button.image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        terminal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        progressbar_label = new Gtk.Label (null);
        progressbar_label.xalign = 0;
        progressbar_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        progressbar = new Gtk.ProgressBar ();
        progressbar.hexpand = true;

        content_area.margin_end = 22;
        content_area.margin_start = 22;
        content_area.attach (logo_stack, 0, 0, 2, 1);
        content_area.attach (progressbar_label, 0, 1, 1, 1);
        content_area.attach (terminal_button, 1, 1, 1, 1);
        content_area.attach (progressbar, 0, 2, 2, 1);

        get_style_context ().add_class ("progress-view");

        terminal_button.toggled.connect (() => {
            if (terminal_button.active) {
                logo_stack.visible_child = terminal_output;
                scroll_to_bottom ();
            } else {
                logo_stack.visible_child = artwork;
            }
        });

        terminal_view.size_allocate.connect (() => attempt_scroll ());

        show_all ();
    }

    private void attempt_scroll () {
        var adj = terminal_output.vadjustment;

        var units_from_end = prev_upper_adj - adj.page_size - adj.value;
        var view_size_difference = adj.upper - prev_upper_adj;
        if (view_size_difference < 0) {
            view_size_difference = 0;
        }

        if (prev_upper_adj <= adj.page_size || units_from_end <= 50) {
            scroll_to_bottom ();
        }

        prev_upper_adj = adj.upper;
    }

    private void scroll_to_bottom () {
        var adj = terminal_output.vadjustment;
        adj.value = adj.upper;
    }

    public string get_log () {
        return terminal_view.buffer.text;
    }

    // TODO: This should receive the disk configuration from the user.
    // For now, it is hard-coded as an example.
    public void start_installation () {
        var installer = new Distinst.Installer ();
        installer.on_error (installation_error_callback);
        installer.on_status (installation_status_callback);

        var config = Distinst.Config ();
        unowned Configuration current_config = Configuration.get_default ();

        config.flags = Distinst.MODIFY_BOOT_ORDER;

        config.hostname = "pop-os";

        config.squashfs = Build.SQUASHFS_PATH;

        config.lang = "en_US.UTF-8";

        config.remove = Build.MANIFEST_REMOVE_PATH;

        //TODO: Use the following
        debug ("language: %s\n", current_config.lang);
        if (current_config.country != null) {
            debug ("country: %s\n", current_config.country);
        } else {
            debug ("no country\n");
        }

        config.keyboard_layout = current_config.keyboard_layout;
        config.keyboard_model = null;
        config.keyboard_variant = current_config.keyboard_variant;

        // Each disk that will have changes made to it should be added to a Disks object. This
        // object will be passed to the install method, and used as a blueprint for how changes
        // to each disk should be made, and where critical partitions are located.
        var disks = new Distinst.Disks ();

        if (disk_config == null) {
            default_disk_configuration (disks);
        } else {
            custom_disk_configuration (disks);
        }

        new Thread<void*> (null, () => {
            if (Installer.App.test_mode) {
                Idle.add (() => {
                    on_success ();
                    return GLib.Source.REMOVE;
                });
            } else {
                stderr.printf ("DEBUG: starting distinst installer\n");
                installer.install ((owned) disks, config);
            }

            return null;
        });
    }

    private void custom_disk_configuration (Distinst.Disks disks) {
        Installer.Mount[] lvm_devices = {};

        foreach (Installer.Mount m in disk_config) {
            if (m.is_lvm ()) {
                lvm_devices += m;
            } else {
                unowned Distinst.Disk disk = disks.get_physical_device (m.parent_disk);
                if (disk == null) {
                    var new_disk = new Distinst.Disk (m.parent_disk);
                    if (new_disk == null) {
                        stderr.printf ("could not find physical device: '%s'\n", m.parent_disk);
                        warning ("could not find physical device: '%s'\n", m.parent_disk);
                        on_error ();
                        return;
                    }

                    disks.push (new_disk);
                    disk = disks.get_physical_device (m.parent_disk);
                }

                unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

                if (partition == null) {
                    stderr.printf ("could not find %s\n", m.partition_path);
                    warning ("could not find %s\n", m.partition_path);
                    on_error ();
                    return;
                }

                if (m.mount_point == "/boot/efi") {
                    if (m.is_valid_boot_mount ()) {
                        var pfs = partition.get_file_system ();
                        if (pfs != Distinst.FileSystemType.FAT16 || pfs != Distinst.FileSystemType.FAT32) {
                            partition.format_with (m.filesystem);
                        }

                        partition.set_mount (m.mount_point);
                        Distinst.PartitionFlag[] flags = { Distinst.PartitionFlag.ESP };
                        partition.set_flags (flags);
                    } else {
                        stderr.printf ("unreachable code path -- efi partition is invalid\n");
                        warning ("unreachable code path -- efi partition is invalid\n");
                        on_error ();
                        return;
                    }
                } else {
                    if (m.filesystem != Distinst.FileSystemType.SWAP) {
                        partition.set_mount (m.mount_point);
                    }

                    partition.format_with (m.filesystem);
                }
            }
        }

        stderr.printf ("configuring lvm partitions\n");
        disks.initialize_volume_groups ();
        foreach (Installer.Mount m in lvm_devices) {
            var vg = m.parent_disk.offset (12);
            unowned Distinst.LvmDevice disk = disks.get_logical_device (vg);
            if (disk == null) {
                stderr.printf ("could not find %s\n", vg);
                warning ("could not find %s\n", vg);
                on_error ();
                return;
            }

            unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

            if (partition == null) {
                stderr.printf ("could not find %s\n", m.partition_path);
                warning ("could not find %s\n", m.partition_path);
                on_error ();
                return;
            }

            if (m.filesystem != Distinst.FileSystemType.SWAP) {
                partition.set_mount (m.mount_point);
            }

            partition.format_and_keep_name (m.filesystem);
        }
    }

    private void default_disk_configuration (Distinst.Disks disks) {
        unowned Configuration current_config = Configuration.get_default ();

        Distinst.LvmEncryption? encryption;
        if (current_config.encryption_password != null) {
            debug ("encrypting");
            encryption = Distinst.LvmEncryption () {
                physical_volume = "cryptdata",
                password = current_config.encryption_password,
                keydata = null
            };
        } else {
            debug ("not encrypting");
            encryption = null;
        }


        // TODO: The following code is an example of API usage. Disk configurations should be
        // passed as a parameter into this method, rather than being hard-coded as it is below.

        // Reads all of the information regarding the specified device and creates an in-memory
        // representation of the disk that actions can be performed against. Any changes made to
        // this disk object will not be written to the disk until after it has been passed into
        // the instal method, along with other disks.
        debug ("disk: %s\n", current_config.disk);
        var disk = new Distinst.Disk (current_config.disk);
        if (disk == null) {
            warning ("could not find %s\n", current_config.disk);
            on_error ();
            return;
        }

        // Obtains the preferred partition table based on what the system is currently loaded with.
        // EFI partitions will need to have both an EFI partition with an `esp` flag, and a root
        // partition; whereas MBR-based installations only require a root partition.
        var bootloader = Distinst.bootloader_detect ();

        // Identify the start of disk by sector
        var start_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.START,
            value = 0
        };

        // Sectors may also be constructed using different units of measurements, such as
        // by megabytes and percents. The library author can choose whichever unit makes
        // more sense for their use cases.
        var boot_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE,
            value = 512
        };

        // Sectors may also use the end of the disk
        var swap_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE_FROM_END,
            value = 4096
        };

        // Identify the end of disk
        var end_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.END,
            value = 0
        };

        // Wipes the partition table clean with a brand new partition table.
        int result = disk.mklabel (bootloader);

        if (result != 0) {
            warning ("unable to write partition table to %s\n", current_config.disk);
            on_error ();
            return;
        }

        var start = disk.get_sector (ref start_sector);
        var end = disk.get_sector (ref boot_sector);

        switch (bootloader) {
            case Distinst.PartitionTable.MSDOS:
                // Adds a new partition builder object which is defined to be a EXT4 partition
                // with the `boot` flag, and shall be mounted to `/boot` after install. This is
                // used to ensure LVM installs will work.
                result = disk.add_partition (
                    new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.EXT4)
                        .partition_type (Distinst.PartitionType.PRIMARY)
                        .flag (Distinst.PartitionFlag.BOOT)
                        .mount ("/boot")
                );

                if (result != 0) {
                    warning ("unable to add boot partition to %s\n", current_config.disk);
                    on_error ();
                    return;
                }

                break;
            case Distinst.PartitionTable.GPT:
                // Adds a new partition builder object which is defined to be a FAT partition
                // with the `esp` flag, and shall be mounted to `/boot/efi` after install. This
                // meets the requirement for an EFI partition with an EFI install.
                result = disk.add_partition (
                    new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.FAT32)
                        .partition_type (Distinst.PartitionType.PRIMARY)
                        .flag (Distinst.PartitionFlag.ESP)
                        .mount ("/boot/efi")
                );

                if (result != 0) {
                    warning ("unable to add EFI partition to %s\n", current_config.disk);
                    on_error ();
                    return;
                }

                break;
        }

        start = disk.get_sector (ref boot_sector);
        end = disk.get_sector (ref end_sector);

        // EFI installs require both an EFI and root partition, so this add a new EXT4
        // partition that is configured to start at the end of the EFI sector, and
        // continue to the end of the disk.
        result = disk.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.LVM)
                .partition_type (Distinst.PartitionType.PRIMARY)
                .logical_volume ("data", encryption)
        );

        if (result != 0) {
            warning ("unable to add lvm partition to %s\n", current_config.disk);
            on_error ();
            return;
        }

        disks.push (disk);

        result = disks.initialize_volume_groups ();

        if (result != 0) {
            warning ("unable to initialize volume groups on %s\n", current_config.disk);
            on_error ();
            return;
        }

        unowned Distinst.LvmDevice lvm_device = disks.find_logical_volume ("data");

        if (lvm_device == null) {
            warning ("unable to find 'data' volume group on %s\n", current_config.disk);
            on_error ();
            return;
        }

        start = lvm_device.get_sector (ref start_sector);
        end = lvm_device.get_sector (ref swap_sector);

        result = lvm_device.add_partition(
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.EXT4)
                .name("root")
                .mount ("/")
        );

        if (result != 0) {
            warning ("unable to add / partition to lvm on %s\n", current_config.disk);
            on_error ();
            return;
        }

        start = lvm_device.get_sector (ref swap_sector);
        end = lvm_device.get_sector (ref end_sector);

        result = lvm_device.add_partition(
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.SWAP)
                .name("swap")
        );

        if (result != 0) {
            warning ("unable to add swap partition to lvm on %s\n", current_config.disk);
            on_error ();
            return;
        }
    }

    private void installation_status_callback (Distinst.Status status) {
        Idle.add (() => {
            if (status.percent == 100 && status.step == Distinst.Step.BOOTLOADER) {
                on_success ();
                return GLib.Source.REMOVE;
            }

            double fraction = ((double) status.percent)/(100.0 * NUM_STEP);
            switch (status.step) {
                case Distinst.Step.PARTITION:
                    progressbar_label.label = _("Partitioning Drive");
                    break;
                case Distinst.Step.EXTRACT:
                    fraction += 2*(1.0/NUM_STEP);
                    progressbar_label.label = _("Extracting Files");
                    break;
                case Distinst.Step.CONFIGURE:
                    fraction += 3*(1.0/NUM_STEP);
                    progressbar_label.label = _("Configuring the System");
                    break;
                case Distinst.Step.BOOTLOADER:
                    fraction += 4*(1.0/NUM_STEP);
                    progressbar_label.label = _("Finishing the Installation");
                    break;
            }

            progressbar_label.label +=  " (%d%%)".printf (status.percent);
            progressbar.fraction = fraction;
            return GLib.Source.REMOVE;
        });
    }

    private void installation_error_callback (Distinst.Error error) {
        Idle.add (() => {
            on_error ();
            return GLib.Source.REMOVE;
        });
    }
}
