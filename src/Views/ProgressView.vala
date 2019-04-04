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

    private Gtk.ProgressBar progressbar;
    private Gtk.Label progressbar_label;
    private const int NUM_STEP = 4;
    private Terminal terminal;

    private Distinst.Installer installer;

    construct {
        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo";
        logo.pixel_size = 128;
        logo.get_style_context ().add_class ("logo");

        terminal = new Terminal (LogHelper.get_default ().buffer);

        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("progress");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var logo_stack = new Gtk.Stack ();
        logo_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        logo_stack.add (artwork);
        logo_stack.add (terminal.container);

        progressbar_label = new Gtk.Label (null);
        progressbar_label.xalign = 0;
        progressbar_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        progressbar = new Gtk.ProgressBar ();
        progressbar.hexpand = true;

        content_area.margin_end = 22;
        content_area.margin_start = 22;
        content_area.attach (logo_stack, 0, 0, 2, 1);
        content_area.attach (progressbar_label, 0, 1, 1, 1);
        content_area.attach (terminal.toggle, 1, 1, 1, 1);
        content_area.attach (progressbar, 0, 2, 2, 1);

        get_style_context ().add_class ("progress-view");

        terminal.toggled.connect ((active) => {
            logo_stack.visible_child = active
                ? (Gtk.Widget) terminal.container
                : (Gtk.Widget) artwork;
        });

        show_all ();
    }

    public string get_log () {
        return terminal.log;
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
            unowned Configuration current_config = Configuration.get_default ();

            stderr.printf ("locale: %s\n", current_config.get_locale ());
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
        installer = new Distinst.Installer ();
        installer.on_error (installation_error_callback);
        installer.on_status (installation_status_callback);

        var config = Distinst.Config ();
        config.flags = Distinst.MODIFY_BOOT_ORDER | Distinst.INSTALL_HARDWARE_SUPPORT;
        config.hostname = "pop-os";

        var casper = casper_dir ();
        config.remove = casper + "/filesystem.manifest-remove";
        config.squashfs = casper + "/filesystem.squashfs";

        unowned Configuration current_config = Configuration.get_default ();
        unowned InstallOptions options = InstallOptions.get_default ();

        config.lang = current_config.get_locale ();
        config.keyboard_layout = current_config.keyboard_layout;
        config.keyboard_model = null;
        config.keyboard_variant = current_config.keyboard_variant;

        Distinst.Disks disks;
        if (current_config.mounts == null) {
            unowned Distinst.InstallOption? option = options.selected_option;

            if (option == null) {
                critical (_("install option is null\n"));
                on_error ();
                return;
            }

            switch (option.tag) {
                case Distinst.InstallOptionVariant.REFRESH:
                    unowned Distinst.RefreshOption refresh = (Distinst.RefreshOption*) option.option;
                    config.old_root = Utils.string_from_utf8 (refresh.get_root_part ());
                    if (current_config.retain_old) {
                        config.flags |= Distinst.KEEP_OLD_ROOT;
                    }

                    break;
                case Distinst.InstallOptionVariant.ALONGSIDE:
                case Distinst.InstallOptionVariant.ERASE:
                case Distinst.InstallOptionVariant.RECOVERY:
                    option.encrypt_pass = current_config.encryption_password;
                    break;
            }

            disks = options.take_disks ();
            var result = option.apply (disks);
            if (result != 0) {
                on_error ();
                return;
            }
        } else {
            disks = new Distinst.Disks ();
            if (!custom_disk_configuration (disks)) {
                on_error ();
                return;
            }
        }

        new Thread<void*> (null, () => {
            if (installer.install ((owned) disks, config) != 0) {
                Idle.add (() => {
                    on_error ();
                    return Source.REMOVE;
                });
            }
            return null;
        });
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
                    if (m.filesystem != Distinst.FileSystem.SWAP) {
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
            var vg = m.parent_disk.offset (12).replace ("--", "-");
            unowned Distinst.LvmDevice disk = disks.get_logical_device (vg);
            if (disk == null) {
                critical ("could not find %s\n", vg);
                return false;
            }

            unowned Distinst.Partition partition = disk.get_encrypted_file_system ();
            if (partition == null) {
                partition = disk.get_partition_by_path (m.partition_path);
                if (partition == null) {
                    critical ("could not find by path %s\n", m.partition_path);
                    return false;
                }
            }

            if (m.filesystem != Distinst.FileSystem.SWAP) {
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

            double fraction = ((double) status.percent) / (100.0 * NUM_STEP);
            switch (status.step) {
                case Distinst.Step.BACKUP:
                    progressbar_label.label = _("Performing Backup Step");
                    break;
                case Distinst.Step.PARTITION:
                    progressbar_label.label = _("Partitioning Drive");
                    break;
                case Distinst.Step.EXTRACT:
                    fraction += (1.0 / NUM_STEP);
                    progressbar_label.label = _("Extracting Files");
                    break;
                case Distinst.Step.CONFIGURE:
                    fraction += 2 * (1.0 / NUM_STEP);
                    progressbar_label.label = _("Configuring the System");
                    break;
                case Distinst.Step.BOOTLOADER:
                    fraction += 3 * (1.0 / NUM_STEP);
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
