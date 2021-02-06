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

    public Installer.Terminal terminal_view { get; construct; }
    private Gtk.ProgressBar progressbar;
    private Gtk.Label progressbar_label;
    private const int NUM_STEP = 5;

    construct {
        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo";
        logo.pixel_size = 128;
        logo.get_style_context ().add_class ("logo");

        unowned LogHelper log_helper = LogHelper.get_default ();
        terminal_view = new Installer.Terminal (log_helper.buffer);

        var logo_stack = new Gtk.Stack ();
        logo_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        logo_stack.add (logo);
        logo_stack.add (terminal_view);

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
                logo_stack.visible_child = terminal_view;
                terminal_view.attempt_scroll ();
            } else {
                logo_stack.visible_child = logo;
            }
        });

        show_all ();
    }

    public string get_log () {
        return terminal_view.buffer.text;
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
        Installer.Daemon.get_default ().on_error.connect (installation_error_callback);
        Installer.Daemon.get_default ().on_status.connect (installation_status_callback);

        var config = InstallerDaemon.InstallConfig ();
        config.flags = Distinst.MODIFY_BOOT_ORDER;
        config.hostname = "elementary-os";
        config.lang = "en_US.UTF-8";

        unowned Configuration current_config = Configuration.get_default ();

        //TODO: Use the following
        debug ("language: %s\n", current_config.lang);
        if (current_config.country != null) {
            debug ("country: %s\n", current_config.country);
        } else {
            config.lang = current_config.lang + "_" + current_config.lang.ascii_up () + ".UTF-8";
        }

        config.keyboard_layout = current_config.keyboard_layout;
        config.keyboard_variant = current_config.keyboard_variant ?? "";

        if (current_config.mounts == null) {
            Installer.Daemon.get_default ().install_with_default_disk_layout (config, current_config.disk, current_config.encryption_password != null, current_config.encryption_password ?? "");
        } else {
            //custom_disk_configuration (disks);
        }
    }

    private void custom_disk_configuration (Distinst.Disks disks) {
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
                        on_error ();
                        return;
                    }

                    disks.push ((owned) new_disk);
                    disk = disks.get_physical_device (m.parent_disk);
                }

                unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

                if (partition == null) {
                    warning ("could not find %s\n", m.partition_path);
                    on_error ();
                    return;
                }

                if (m.mount_point == "/boot/efi") {
                    if (m.is_valid_boot_mount ()) {
                        if (m.should_format ()) {
                            partition.format_with (m.filesystem);
                        }

                        partition.set_mount (m.mount_point);
                        partition.set_flags ({ Distinst.PartitionFlag.ESP });
                    } else {
                        warning ("unreachable code path -- efi partition is invalid\n");
                        on_error ();
                        return;
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
            var vg = m.parent_disk.offset (12);
            unowned Distinst.LvmDevice disk = disks.get_logical_device (vg);
            if (disk == null) {
                warning ("could not find %s\n", vg);
                on_error ();
                return;
            }

            unowned Distinst.Partition partition = disk.get_partition_by_path (m.partition_path);

            if (partition == null) {
                warning ("could not find %s\n", m.partition_path);
                on_error ();
                return;
            }

            if (m.filesystem != Distinst.FileSystem.SWAP) {
                partition.set_mount (m.mount_point);
            }

            if (m.should_format ()) {
                partition.format_and_keep_name (m.filesystem);
            }
        }
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
                case Distinst.Step.PARTITION:
                    progressbar_label.label = _("Partitioning Drive");
                    break;
                case Distinst.Step.EXTRACT:
                    fraction += 2 * (1.0 / NUM_STEP);
                    progressbar_label.label = _("Extracting Files");
                    break;
                case Distinst.Step.CONFIGURE:
                    fraction += 3 * (1.0 / NUM_STEP);
                    progressbar_label.label = _("Configuring the System");
                    break;
                case Distinst.Step.BOOTLOADER:
                    fraction += 4 * (1.0 / NUM_STEP);
                    progressbar_label.label = _("Finishing the Installation");
                    break;
            }

            progressbar_label.label += " (%d%%)".printf (status.percent);
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
