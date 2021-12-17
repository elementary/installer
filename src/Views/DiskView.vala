// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016 elementary LLC. (https://elementary.io)
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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Installer.DiskView : OptionsView {
    public signal void next_step ();

    public DiskView () {
        Object (
            cancellable: true,
            artwork: "disks",
            title: _("Select a drive")
        );
    }

    construct {
        next_button.label = _("Erase and Install");
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;
        next_button.clicked.connect (() => next_step ());

        show_all ();
    }

    // If possible, open devices in a different thread so that the interface stays awake.
    public async void load (uint64 minimum_disk_size) {
        const uint64 MSDOS_MAX_SECTORS = 4294967296 - 1;

        var install_options = InstallOptions.get_default ();
        unowned Distinst.InstallOptions options = install_options.get_updated_options ();

        base.clear_options();

        foreach (unowned Distinst.EraseOption disk in options.get_erase_options ()) {
            string logo = Utils.string_from_utf8 (disk.get_linux_icon ());
            string label = Utils.string_from_utf8 (disk.get_model ());
            string details = "%s %.1f GiB".printf (
                Utils.string_from_utf8 (disk.get_device_path ()),
                (double) disk.get_sectors () / SECTORS_AS_GIB
            );

            // Ensure that the user cannot select a disk that is too large for BIOS installs.
            bool msdos_too_large =
                Distinst.bootloader_detect () == Distinst.PartitionTable.MSDOS
                && disk.get_sectors () > MSDOS_MAX_SECTORS;

            base.add_option(logo, label, details, (button) => {
                if (disk.meets_requirements () && !msdos_too_large) {
                    button.notify["active"].connect (() => {
                        if (button.active) {
                            base.options.get_children ().foreach ((child) => {
                                if (child is Gtk.ToggleButton) {
                                    ((Gtk.ToggleButton)child).active = child == button;
                                }
                            });

                            if (install_options.has_recovery ()) {
                                var recovery = options.get_recovery_option ();

                                install_options.selected_option = new Distinst.InstallOption () {
                                    tag = Distinst.InstallOptionVariant.RECOVERY,
                                    option = (void*) recovery,
                                    encrypt_pass = null
                                };
                            } else {
                                install_options.selected_option = new Distinst.InstallOption () {
                                    tag = Distinst.InstallOptionVariant.ERASE,
                                    option = (void*) disk,
                                    encrypt_pass = null
                                };
                            }

                            next_button.sensitive = true;
                        } else {
                            next_button.sensitive = false;
                        }
                    });
                    button.key_press_event.connect ((event) => handle_key_press (button, event));
                } else {
                    button.sensitive = false;
                    if (msdos_too_large) {
                        button.set_tooltip_text (_("Maximum size of MSDOS partition table is 2TiB. Switch to EFI for GPT table support."));
                    } else {
                        button.set_tooltip_text (_("Disk does not meet the minimum requirement"));
                    }
                }
            });
        }

        base.sort_sensitive ();
    }

    private bool handle_key_press (Gtk.Button button, Gdk.EventKey event) {
        if (event.keyval == Gdk.Key.Return && next_button.sensitive) {
            button.clicked ();
            next_button.clicked ();
            return true;
        } else if (event.keyval == Gdk.Key.Return && !next_button.sensitive) {
            return true;
        }

        return false;
    }

    public void reset() {
        next_button.sensitive = false;
    }
}
