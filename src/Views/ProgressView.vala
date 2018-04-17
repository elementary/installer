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

    private double prev_upper_adj = 0;
    private Gtk.ScrolledWindow terminal_output;
    public Gtk.TextView terminal_view { get; construct; }
    private Gtk.ProgressBar progressbar;
    private Gtk.Label progressbar_label;
    private const int NUM_STEP = 4;

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

    private string casper_dir () {
        var cdrom = "/cdrom";

        try {
            var cdrom_dir = File.new_for_path (cdrom);
            var iter = cdrom_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo info;
            while ((info = iter.next_file ()) != null) {
                var name = info.get_name ();
                if (name.has_prefix ("casper")) {
                    return cdrom + "/" + name;
                }
            }
        } catch (GLib.Error e) {
            critical ("failed to find casper dir automatically: %s\n", e.message);
        }

        return cdrom + "/casper";
    }

    public void start_installation () {
        if (Installer.App.test_mode) {
            new Thread<void*> (null, () => {
                fake_status (Distinst.Step.PARTITION);
                fake_status (Distinst.Step.EXTRACT);
                fake_status (Distinst.Step.CONFIGURE);
                fake_status (Distinst.Step.BOOTLOADER);
                return null;
            });
        } else {
            real_installation ();
        }
    }

    public void real_installation () {
        var installer = new Distinst.Installer ();
        installer.on_error (installation_error_callback);
        installer.on_status (installation_status_callback);

        var config = Distinst.Config ();
        config.flags = Distinst.MODIFY_BOOT_ORDER;
        config.hostname = "pop-os";

        var casper = casper_dir ();
        config.remove = casper + "/filesystem.manifest-remove";
        config.squashfs = casper + "/filesystem.squashfs";

        unowned Configuration current_config = Configuration.get_default ();

        var recovery = Recovery.disk ();

        debug ("language: %s\n", current_config.lang);
        if (current_config.country != null) {
            debug ("country: %s\n", current_config.country);
            config.lang = current_config.lang + "_" + current_config.country + ".UTF-8";
        } else {
            debug ("no country\n");
            config.lang = current_config.lang + ".UTF-8";
        }

        config.keyboard_layout = current_config.keyboard_layout;
        config.keyboard_model = null;
        config.keyboard_variant = current_config.keyboard_variant;

        var disks = new Distinst.Disks ();
        if (recovery != null) {
            if (!recovery_disk_configuration (disks, recovery)) {
                on_error ();
                return;
            }
        } else if (current_config.mounts == null) {
            if (!default_disk_configuration (disks)) {
                on_error ();
                return;
            }
        } else {
            if (!custom_disk_configuration (disks)) {
                on_error ();
                return;
            }
        }

        new Thread<void*> (null, () => {
            installer.install ((owned) disks, config);
            return null;
        });
    }

    private bool recovery_disk_configuration (Distinst.Disks disks, string recovery_disk) {
        unowned Configuration current_config = Configuration.get_default ();

        var encrypted_vg = Distinst.generate_unique_id ("cryptdata");
        var root_vg = Distinst.generate_unique_id ("data");
        if (encrypted_vg == null || root_vg == null) {
            critical ("unable to generate unique volume group IDs\n");
            return false;
        }

        Distinst.LvmEncryption? encryption;
        if (current_config.encryption_password != null) {
            debug ("encrypting");
            encryption = Distinst.LvmEncryption () {
                physical_volume = encrypted_vg,
                password = current_config.encryption_password,
                keydata = null
            };
        } else {
            debug ("not encrypting");
            encryption = null;
        }

        debug ("disk: %s\n", recovery_disk);
        var disk = new Distinst.Disk (recovery_disk);
        if (disk == null) {
            critical ("could not find physical device: '%s'\n", recovery_disk);
            return false;
        }

        var bootloader = Distinst.bootloader_detect ();

        var start_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.START,
            value = 0
        };

        var swap_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE_FROM_END,
            value = 4096
        };

        var end_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.END,
            value = 0
        };

        string? efi_part = Recovery.efi_partition ();
        string? recovery_part = Recovery.recovery_partition ();
        string? lvm_part = Recovery.lvm_partition();

        if (efi_part != null) {
            debug ("efi_part: %s\n", efi_part);

            unowned Distinst.Partition partition = disk.get_partition_by_path (efi_part);

            if (partition == null) {
                critical ("could not find %s on %s\n", efi_part, recovery_disk);
                return false;
            }

            partition.set_mount ("/boot/efi");
        } else {
            critical ("EFI partition not found on %s", recovery_disk);
            return false;
        }

        if (recovery_part != null) {
            debug("recovery_part: %s\n", recovery_part);

            //TODO: Find recovery partition using /cdrom mount, do not format it, update it with correct information

            unowned Distinst.Partition partition = disk.get_partition_by_path (recovery_part);

            if (partition == null) {
                critical ("could not find %s on %s\n", recovery_part, recovery_disk);
                return false;
            }
        } else {
            critical ("recovery partition not found on %s", recovery_disk);
            return false;
        }

        int lvm_num;
        uint64 start;
        uint64 end;

        if (lvm_part != null) {
            debug("lvm_part: %s\n", lvm_part);

            unowned Distinst.Partition partition = disk.get_partition_by_path (lvm_part);

            if (partition == null) {
                critical ("could not find %s on %s\n", lvm_part, recovery_disk);
                return false;
            }

            lvm_num = partition.get_number ();
            start = partition.get_start_sector ();
            end = partition.get_end_sector ();
        } else {
            critical ("LVM partition not found on %s", recovery_disk);
            return false;
        }

        disk.remove_partition (lvm_num);

        int result = disk.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.LVM)
                .partition_type (Distinst.PartitionType.PRIMARY)
                .logical_volume (root_vg, encryption)
        );

        if (result != 0) {
            critical ("unable to add lvm partition to %s", recovery_disk);
            return false;
        }

        disks.push ((owned) disk);

        result = disks.initialize_volume_groups ();

        if (result != 0) {
            critical ("unable to initialize volume groups on %s", recovery_disk);
            return false;
        }

        unowned Distinst.LvmDevice lvm_device = disks.find_logical_volume (root_vg);

        if (lvm_device == null) {
            critical ("unable to find '%s' volume group on %s", root_vg, recovery_disk);
            return false;
        }

        start = lvm_device.get_sector (ref start_sector);
        end = lvm_device.get_sector (ref swap_sector);

        result = lvm_device.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.EXT4)
                .name("root")
                .mount ("/")
        );

        if (result != 0) {
            critical ("unable to add / partition to lvm on %s", recovery_disk);
            return false;
        }

        start = lvm_device.get_sector (ref swap_sector);
        end = lvm_device.get_sector (ref end_sector);

        result = lvm_device.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.SWAP)
                .name("swap")
        );

        if (result != 0) {
            critical ("unable to add swap partition to lvm on %s", recovery_disk);
            return false;
        }

        return true;
    }

    private bool default_disk_configuration (Distinst.Disks disks) {
        unowned Configuration current_config = Configuration.get_default ();

        var encrypted_vg = Distinst.generate_unique_id ("cryptdata");
        var root_vg = Distinst.generate_unique_id ("data");
        if (encrypted_vg == null || root_vg == null) {
            critical ("unable to generate unique volume group IDs\n");
            return false;
        }

        Distinst.LvmEncryption? encryption;
        if (current_config.encryption_password != null) {
            debug ("encrypting");
            encryption = Distinst.LvmEncryption () {
                physical_volume = encrypted_vg,
                password = current_config.encryption_password,
                keydata = null
            };
        } else {
            debug ("not encrypting");
            encryption = null;
        }

        debug ("disk: %s\n", current_config.disk);
        var disk = new Distinst.Disk (current_config.disk);
        if (disk == null) {
            critical ("could not find %s", current_config.disk);
            return false;
        }

        var bootloader = Distinst.bootloader_detect ();

        var start_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.START,
            value = 0
        };

        var boot_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE,
            value = 512
        };

        var recovery_sector = Distinst.Sector() {
            flag = Distinst.SectorKind.MEGABYTE,
            value = 512 + 4096
        };

        var swap_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.MEGABYTE_FROM_END,
            value = 4096
        };

        var end_sector = Distinst.Sector () {
            flag = Distinst.SectorKind.END,
            value = 0
        };

        // Prepares a new partition table.
        int result = disk.mklabel (bootloader);

        if (result != 0) {
            critical ("unable to write partition table to %s", current_config.disk);
            return false;
        }

        var start = disk.get_sector (ref start_sector);
        var end = disk.get_sector (ref boot_sector);

        switch (bootloader) {
            case Distinst.PartitionTable.MSDOS:
                // This is used to ensure LVM installs will work with BIOS
                result = disk.add_partition (
                    new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.EXT4)
                        .partition_type (Distinst.PartitionType.PRIMARY)
                        .flag (Distinst.PartitionFlag.BOOT)
                        .mount ("/boot")
                );

                if (result != 0) {
                    critical ("unable to add boot partition to %s", current_config.disk);
                    return false;
                }

                break;
            case Distinst.PartitionTable.GPT:
                // A FAT32 partition is required for EFI installs
                result = disk.add_partition (
                    new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.FAT32)
                        .partition_type (Distinst.PartitionType.PRIMARY)
                        .flag (Distinst.PartitionFlag.ESP)
                        .mount ("/boot/efi")
                );

                if (result != 0) {
                    critical ("unable to add EFI partition to %s", current_config.disk);
                    return false;
                }

                break;
        }

        start = disk.get_sector (ref boot_sector);
        end = disk.get_sector (ref recovery_sector);

        result = disk.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.FAT32)
                .name("recovery")
                .mount ("/recovery")
        );

        start = disk.get_sector (ref recovery_sector);
        end = disk.get_sector (ref end_sector);

        result = disk.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.LVM)
                .partition_type (Distinst.PartitionType.PRIMARY)
                .logical_volume (root_vg, encryption)
        );

        if (result != 0) {
            critical ("unable to add lvm partition to %s", current_config.disk);
            return false;
        }

        disks.push ((owned) disk);

        result = disks.initialize_volume_groups ();

        if (result != 0) {
            critical ("unable to initialize volume groups on %s", current_config.disk);
            return false;
        }

        unowned Distinst.LvmDevice lvm_device = disks.find_logical_volume (root_vg);

        if (lvm_device == null) {
            critical ("unable to find '%s' volume group on %s", root_vg, current_config.disk);
            return false;
        }

        start = lvm_device.get_sector (ref start_sector);
        end = lvm_device.get_sector (ref swap_sector);

        result = lvm_device.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.EXT4)
                .name("root")
                .mount ("/")
        );

        if (result != 0) {
            critical ("unable to add / partition to lvm on %s", current_config.disk);
            return false;
        }

        start = lvm_device.get_sector (ref swap_sector);
        end = lvm_device.get_sector (ref end_sector);

        result = lvm_device.add_partition (
            new Distinst.PartitionBuilder (start, end, Distinst.FileSystemType.SWAP)
                .name("swap")
        );

        if (result != 0) {
            critical ("unable to add swap partition to lvm on %s", current_config.disk);
            return false;
        }

        return true;
    }

    private bool custom_disk_configuration (Distinst.Disks disks) {
        unowned Configuration config = Configuration.get_default ();
        Installer.Mount[] lvm_devices = {};

        foreach (Installer.Mount m in config.mounts) {
            if (m.is_lvm ()) {
                lvm_devices += m;
            } else {
                unowned Distinst.Disk disk = disks.get_physical_device (m.parent_disk);
                if (disk == null) {
                    var new_disk = new Distinst.Disk (m.parent_disk);
                    if (new_disk == null) {
                        warning ("could not find physical device: '%s'\n", m.parent_disk);
                        return false;
                    }

                    disks.push ((owned) new_disk);
                    disk = disks.get_physical_device (m.parent_disk);
                }

                unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

                if (partition == null) {
                    critical ("could not find %s\n", m.partition_path);
                    return false;
                }

                if (m.mount_point == "/boot/efi") {
                    if (m.is_valid_boot_mount ()) {
                        if (m.should_format ()) {
                            partition.format_with (m.filesystem);
                        }

                        partition.set_mount (m.mount_point);
                        partition.set_flags ({ Distinst.PartitionFlag.ESP });
                    } else {
                        critical ("unreachable code path -- efi partition is invalid\n");
                        return false;
                    }
                } else {
                    if (m.filesystem != Distinst.FileSystemType.SWAP) {
                        partition.set_mount (m.mount_point);
                    }

                    if (m.mount_point == "/boot") {
                        partition.set_flags ({ Distinst.PartitionFlag.BOOT });
                    }

                    if (m.should_format ()) {
                        partition.format_with (m.filesystem);
                    }
                }
            }
        }

        disks.initialize_volume_groups ();

        foreach (Installer.LuksCredentials cred in config.luks) {
            disks.decrypt_partition (cred.device, Distinst.LvmEncryption () {
                physical_volume = cred.pv,
                password = cred.password,
                keydata = null
            });
        }

        foreach (Installer.Mount m in lvm_devices) {
            var vg = m.parent_disk.offset (12);
            unowned Distinst.LvmDevice disk = disks.get_logical_device (vg);
            if (disk == null) {
                critical ("could not find %s\n", vg);
                return false;
            }

            unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

            if (partition == null) {
                critical ("could not find %s\n", m.partition_path);
                return false;
            }

            if (m.filesystem != Distinst.FileSystemType.SWAP) {
                partition.set_mount (m.mount_point);
            }

            if (m.should_format ()) {
                partition.format_and_keep_name (m.filesystem);
            }
        }

        return true;
    }

    private void fake_status (Distinst.Step step) {
        for (var percent = 0; percent <= 100; percent++) {
            Distinst.Status status = Distinst.Status () {
                step = step,
                percent = percent
            };
            installation_status_callback (status);
            GLib.Thread.usleep (10000);
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
                    fraction += (1.0/NUM_STEP);
                    progressbar_label.label = _("Extracting Files");
                    break;
                case Distinst.Step.CONFIGURE:
                    fraction += 2*(1.0/NUM_STEP);
                    progressbar_label.label = _("Configuring the System");
                    break;
                case Distinst.Step.BOOTLOADER:
                    fraction += 3*(1.0/NUM_STEP);
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
