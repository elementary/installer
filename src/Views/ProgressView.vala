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

using Distinst;

extern void exit(int exit_code);

public class ProgressView : AbstractInstallerView {
    public signal void on_success ();
    public signal void on_error ();

    private Gtk.ProgressBar progressbar;
    private Gtk.Label progressbar_label;
    private const int NUM_STEP = 5;

    construct {
        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo";
        logo.pixel_size = 128;
        logo.get_style_context ().add_class ("logo");

        unowned LogHelper log_helper = LogHelper.get_default ();
        var terminal_view = new Gtk.TextView.with_buffer (log_helper.buffer);
        terminal_view.bottom_margin = terminal_view.top_margin = terminal_view.left_margin = terminal_view.right_margin = 12;
        terminal_view.editable = false;
        terminal_view.cursor_visible = true;
        terminal_view.monospace = true;
        terminal_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        terminal_view.get_style_context ().add_class ("terminal");

        var terminal_output = new Gtk.ScrolledWindow (null, null);
        terminal_output.hscrollbar_policy = Gtk.PolicyType.NEVER;
        terminal_output.expand = true;
        terminal_output.add (terminal_view);

        var logo_stack = new Gtk.Stack ();
        logo_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        logo_stack.add (logo);
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
            } else {
                logo_stack.visible_child = logo;
            }
        });

        show_all ();
    }

    // TODO: This should receive the disk configuration from the user.
    // For now, it is hard-coded as an example.
    public void start_installation () {
        var installer = new Distinst.Installer ();
        installer.on_error (installation_error_callback);
        installer.on_status (installation_status_callback);

        var config = Config ();
        unowned Configuration current_config = Configuration.get_default ();
        config.squashfs = Build.SQUASHFS_PATH;
        config.lang = "en_US.UTF-8";
        config.remove = Build.MANIFEST_REMOVE_PATH;

        // TODO: The following code is an example of API usage. Disk configurations should be
        // passed as a parameter into this method, rather than being hard-coded as it is below.

        // Reads all of the information regarding the specified device and creates an in-memory
        // representation of the disk that actions can be performed against. Any changes made to
        // this disk object will not be written to the disk until after it has been passed into
        // the instal method, along with other disks.
        Disk disk = new Disk (current_config.disk);
        if (disk == null) {
            stderr.printf("could not find %s\n", current_config.disk);
            exit(1);
        }

        // Obtains the preferred partition table based on what the system is currently loaded with.
        // EFI partitions will need to have both an EFI partition with an `esp` flag, and a root
        // partition; whereas MBR-based installations only require a root partition.
        PartitionTable bootloader = bootloader_detect ();

        // Identify the start of disk by sector
        var start_sector = Sector() {
            flag = SectorKind.START,
            value = 0
        };

        // Identify the end of disk
        var end_sector = Sector() {
            flag = SectorKind.END,
            value = 0
        };

        switch (bootloader) {
            case PartitionTable.MSDOS:
                // Wipes the partition table clean with a brand new MSDOS partition table.
                if (disk.mklabel (bootloader) != 0) {
                    stderr.printf("unable to write MSDOS partition table to %s\n", current_config.disk);
                    exit(1);
                }

                // Obtains the start and end values using a human-readable abstraction.
                var start = disk.get_sector (start_sector);
                var end = disk.get_sector (end_sector);

                // Adds a newly-created partition builder object to the disk. This object is
                // defined as an EXT4 partition with the `boot` partition flag, and shall be
                // mounted to `/` within the `/etc/fstab` of the installed system.
                int result = disk.add_partition(
                    new PartitionBuilder (start, end, FileSystemType.EXT4)
                        .partition_type (PartitionType.PRIMARY)
                        .flag (PartitionFlag.BOOT)
                        .mount ("/")
                );

                if (result != 0) {
                    stderr.printf ("unable to add partition to %s\n", current_config.disk);
                    exit(1);
                }

                break;
            case PartitionTable.GPT:
                stderr.printf("mklabel\n");
                if (disk.mklabel (bootloader) != 0) {
                    stderr.printf ("unable to write GPT partition table to %s\n", current_config.disk);
                    exit (1);
                }

                // Sectors may also be constructed using different units of measurements, such as
                // by megabytes and percents. The library author can choose whichever unit makes
                // more sense for their use cases.
                var efi_sector = Sector() {
                    flag = SectorKind.MEGABYTE,
                    value = 512
                };

                var start = disk.get_sector (start_sector);
                var end = disk.get_sector (efi_sector);

                // Adds a new partitition builder object which is defined to be a FAT partition
                // with the `esp` flag, and shall be mounted to `/boot/efi` after install. This
                // meets the requirement for an EFI partition with an EFI install.
                int result = disk.add_partition(
                    new PartitionBuilder (start, end, FileSystemType.FAT32)
                        .partition_type (PartitionType.PRIMARY)
                        .flag (PartitionFlag.ESP)
                        .mount ("/boot/efi")
                );

                if (result != 0) {
                    stderr.printf ("unable to add EFI partition to %s\n", current_config.disk);
                    exit (1);
                }

                start = disk.get_sector (efi_sector);
                end = disk.get_sector (end_sector);

                // EFI installs require both an EFI and root partition, so this add a new EXT4
                // partition that is configured to start at the end of the EFI sector, and
                // continue to the end of the disk.
                result = disk.add_partition (
                    new PartitionBuilder (start, end, FileSystemType.EXT4)
                        .partition_type (PartitionType.PRIMARY)
                        .mount ("/")
                );

                if (result != 0) {
                    stderr.printf ("unable to add / partition to %s\n", current_config.disk);
                    exit (1);
                }

                break;
        }

        // Each disk that will have changes made to it should be added to a Disks object. This
        // object will be passed to the install method, and used as a blueprint for how changes
        // to each disk should be made, and where critical partitions are located.
        Disks disks = new Disks ();
        disks.push (disk);

        new Thread<void*> (null, () => {
            installer.install (disks, config);
            return null;
        });
    }

    private void installation_status_callback (Status status) {
        Idle.add (() => {
            if (status.percent == 100 && status.step == Step.BOOTLOADER) {
                on_success ();
                return GLib.Source.REMOVE;
            }

            double fraction = ((double) status.percent)/(100.0 * NUM_STEP);
            switch (status.step) {
                case Step.PARTITION:
                    progressbar_label.label = _("Partitioning Drive");
                    break;
                case Step.EXTRACT:
                    fraction += 2*(1.0/NUM_STEP);
                    progressbar_label.label = _("Extracting Files");
                    break;
                case Step.CONFIGURE:
                    fraction += 3*(1.0/NUM_STEP);
                    progressbar_label.label = _("Configuring the System");
                    break;
                case Step.BOOTLOADER:
                    fraction += 4*(1.0/NUM_STEP);
                    progressbar_label.label = _("Finishing the Installation");
                    break;
            }

            progressbar_label.label +=  " (%d%%)".printf(status.percent);
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
