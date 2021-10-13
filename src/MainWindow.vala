// Copyright 2016-2017 elementary LLC (https://elementary.io)
// Copyright 2018-2021 System76 <info@system76.com>
//
// SPDX-FileContributor: Corentin Noël <corentin@elementary.io>
// SPDX-FileContributor: Michael Murphy <michael@system76.com>
// SPDX-License-Identifier: GPL-3.0-or-later

public struct DecryptSignals {
    public ulong request;
    public DistinstSignals result;
}

public struct DistinstSignals {
    public ulong failed;
    public ulong success;
}

public class Installer.MainWindow : Gtk.Dialog {
    private Gtk.Stack stack;

    private bool check_ignored = false;
    private DiskView disk_view;
    private EncryptView encrypt_view;
    private ErrorView error_view;
    private Installer.CheckView check_view;
    private KeyboardLayoutView keyboard_layout_view;
    private LanguageView language_view;
    private PartitioningView partitioning_view;
    private ProgressView progress_view;
    private SuccessView success_view;
    private TryInstallView try_install_view;
    private UserView user_view;

    /** Refresh install path */
    private RefreshView refresh_view;
    private EncryptedPartitionView encrypted_partition_view;
    private DecryptionView decryption_view;
    private RefreshOSView refresh_os_view;

    private uint64 minimum_disk_size;

    private DateTime? start_date = null;
    private DateTime? end_date = null;

    private DistinstIface distinst;

    private bool refresh_mode = false;
    private string pretty_name;
    private string version;

    private EncryptedDevice[] encrypted;
    private OsEntry[] boot_entries_discovered;
    private OsInfo[] os_discovered;

    private ulong? disk_rescan_signal = null;
    private ulong? decrypt_signal = null;
    private bool searching_for_boot_entries = false;
    private bool searching_for_encrypted_devices = false;

    public MainWindow (DistinstIface distinst) {
        Object (
            deletable: false,
            height_request: 700,
            icon_name: "system-os-installer",
            resizable: true,
            width_request: 950,
            use_header_bar: 1
        );

        this.distinst = distinst;
    }

    construct {
        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        get_content_area ().add (stack);
        get_style_context ().add_class ("os-installer");

        const uint64 DEFAULT_MINIMUM_SIZE = 5000000000;
        minimum_disk_size = Distinst.minimum_disk_size (DEFAULT_MINIMUM_SIZE / 512);

        unowned InstallOptions options = InstallOptions.get_default ();
        options.set_minimum_size (minimum_disk_size);

        weak Gtk.HeaderBar? headerbar = (Gtk.HeaderBar) get_header_bar ();

        this.pretty_name = Utils.get_pretty_name();
        this.version = Utils.get_version_id();

        Idle.add(() => {
            //  this.distinst.decrypt_err.connect((why) => {
            //      this.decryption_view.failed(why);
            //  });

            //  this.distinst.decrypt_ok.connect(() => {
            //      this.decryption_view.success();
            //      this.os_search();
            //  });

            this.distinst.os_entries_err.connect((why) => {
                stderr.printf("failed to locate OS boot entries: %s\n", why);
                this.searching_for_boot_entries = false;
            });

            this.distinst.os_entries_ok.connect((entries) => {
                stderr.printf("Found OS boot entries\n");
                this.boot_entries_discovered = entries;
                this.searching_for_boot_entries = false;
            });

            this.distinst.encrypted_devices_err.connect((why) => {
                stderr.printf("failed to locate encrypted devices: %s\n", why);
                this.searching_for_encrypted_devices = false;
            });

            this.distinst.encrypted_devices_ok.connect((devices) => {
                stderr.printf("located encrypted devices\n");
                this.encrypted = devices;
                this.searching_for_encrypted_devices = false;
            });

            this.distinst.os_search_err.connect((why) => {
                stderr.printf("failed to find an OS: %s\n", why);
                this.load_refresh_view();
                bool can_select = this.encrypted.length != 0;
                this.refresh_view.search_failure(why, can_select);
            });

            this.distinst.os_search_ok.connect((info) => {
                stderr.printf("found an OS\n");
                this.os_discovered = info;
                this.load_refresh_os_view();
            });

            this.os_entries();

            Timeout.add(100, () => {
                if (this.searching_for_boot_entries) {
                    return GLib.Source.CONTINUE;
                }

                if (this.boot_entries_discovered.length != 0) {
                    this.refresh_mode = true;
                    headerbar.title = _("Refresh or Install %s").printf (this.pretty_name);
                    this.os_entries();
                } else {
                    headerbar.title = _("Install %s").printf (this.pretty_name);
                }

                return GLib.Source.REMOVE;
            });

            return GLib.Source.REMOVE;
        });

        language_view = new LanguageView ();
        language_view.next_step.connect (() => load_keyboard_view ());
        stack.add (language_view);
    }

    /** Controls the behavior of successful and unsuccessful decryption attempts. */
    private void decrypt(string uuid) {
        if (this.decrypt_signal != null) {
            this.distinst.disconnect(this.decrypt_signal);
        }

        this.decrypt_signal = this.decryption_view.decrypt.connect((key) => {
            // TODO: Use this instead, when we can replace Distinst V1
            // this.distinst.decrypt(uuid, key);

            var options = InstallOptions.get_default ();
            unowned Distinst.Disks disks = options.borrow_disks ();

            unowned Distinst.Partition? partition = disks.get_partition_by_uuid (uuid);

            if (null == partition) {
                debug ("unable to find partition after decryption");
                return;
            }

            unowned uint8[] device_path = partition.get_device_path ();
            string path = Utils.string_from_utf8 (device_path);

            try {
                options.decrypt (path, "cryptdata", key);

                this.decryption_view.reset();

                if (this.disk_rescan_signal != null) {
                    this.distinst.disconnect(this.disk_rescan_signal);
                }

                this.disk_rescan_signal = this.distinst.disk_rescan_complete.connect(() => {
                    this.os_search();
                    this.distinst.disconnect(this.disk_rescan_signal);
                    this.disk_rescan_signal = null;
                });

                this.distinst.disk_rescan();
            } catch (Error e) {
                this.decryption_view.failed(e.message);
                warning ("failed to decrypt: %s", e.message);
            }
        });
    }

    private void encrypted_devices() {
        try {
            this.distinst.encrypted_devices();
            this.searching_for_encrypted_devices = true;
        } catch (Error e) {
            warning("failed to search for encrypted devices: %s", e.message);
            return;
        }
    }

    private bool is_oem_mode() {
        try {
            return this.distinst.is_oem_mode();
        } catch (Error e) {
            warning("failed to check if in OEM mode: %s", e.message);
            return false;
        }
    }

    private void os_entries() {
        try {
            this.distinst.os_entries();
            this.searching_for_boot_entries = true;
        } catch (Error e) {
            warning("failed to search for OS boot entries: %s", e.message);
            return;
        }
    }

    private void os_search() {
        try {
            this.distinst.os_search();
        } catch (Error e) {
            warning("failed to initiate search of operating systems: %s", e.message);
        }
    }

    /** Offer to decrypt a given encrypted block device. */
    private void load_decrypt_view(string uuid) {
        if (this.decryption_view == null) {
            this.decryption_view = new DecryptionView ();
            this.stack.add(this.decryption_view);
        }

        this.stack.visible_child = this.decryption_view;
        this.decryption_view.reset();
        this.decrypt(uuid);
    }

    /*
     * We need to load all the view after the language has being chosen and set.
     * We need to rebuild the view everytime the next button is clicked to reflect language changes.
     */
    private void load_keyboard_view () {
        if (keyboard_layout_view == null) {
            keyboard_layout_view = new KeyboardLayoutView ();
            keyboard_layout_view.previous_view = language_view;
            keyboard_layout_view.next_step.connect (load_install_options);

            stack.add (keyboard_layout_view);
        }

        stack.visible_child = keyboard_layout_view;
    }

    private void load_user_view(Gtk.Widget prev_view, Fn load_prev_view, Fn load_next_view) {
        if (user_view == null) {
            user_view = new UserView();

            user_view.next_step.connect (() => load_next_view ());

            stack.add (user_view);
        }

        user_view.previous_view = prev_view;
        stack.visible_child = user_view;
        user_view.grab_focus ();
    }

    private void load_install_options() {
        if (this.is_oem_mode()) {
            var opts = InstallOptions.get_default ();
            unowned Distinst.InstallOptions options = opts.get_options ();
            var recovery = options.get_recovery_option ();

            InstallOptions.get_default ().selected_option = new Distinst.InstallOption () {
                tag = Distinst.InstallOptionVariant.RECOVERY,
                option = (void*) recovery,
                encrypt_pass = null
            };

            load_user_view (keyboard_layout_view, load_keyboard_view, load_encrypt_view);
        } else if (this.refresh_mode) {
            load_refresh_view();
        } else {
            load_try_install_view ();
        }
    }

    private void load_refresh_view() {
        if (this.disk_rescan_signal != null) {
            this.distinst.disconnect(this.disk_rescan_signal);
        }

        this.disk_rescan_signal = this.distinst.disk_rescan_complete.connect(() => {
            this.distinst.disconnect(this.disk_rescan_signal);
            this.disk_rescan_signal = null;

            this.encrypted_devices();

            Timeout.add(100, () => {
                // Do not pass until OS entries have been gathered.
                if (this.searching_for_boot_entries || this.searching_for_encrypted_devices) {
                    return GLib.Source.CONTINUE;
                }

                if (this.refresh_view == null) {
                    this.refresh_view = new RefreshView (this.pretty_name, this.version);

                    this.refresh_view.previous_view = keyboard_layout_view;

                    this.refresh_view.cancel.connect (() => {
                        this.stack.visible_child = this.keyboard_layout_view;
                    });

                    this.refresh_view.refresh.connect(() => {
                        Configuration.get_default ().retain_old = true;
                        this.load_refresh_os_view();
                    });

                    this.refresh_view.install.connect(() => {
                        Configuration.get_default ().retain_old = false;
                        this.load_try_install_view();
                    });

                    this.stack.add(this.refresh_view);
                }

                if (this.boot_entries_discovered.length == 0 || this.encrypted.length == 0) {
                    this.refresh_view.disable_refresh();
                } else {
                    this.refresh_view.enable_refresh();
                }

                this.stack.visible_child = refresh_view;

                return GLib.Source.REMOVE;
            });
        });

        this.distinst.disk_rescan();
    }

    private void load_refresh_os_view() {
        if (this.refresh_os_view == null) {
            this.refresh_os_view = new RefreshOSView();

            this.refresh_os_view.cancel.connect(() => {
                this.load_try_install_view();
            });

            this.refresh_os_view.choose_another.connect(() => {
                this.load_encrypted_partition_view();
            });

            this.refresh_os_view.next_step.connect(() => {
                load_progress_view();
            });

            this.stack.add(this.refresh_os_view);
        }

        // TODO: Use Distinst DBus service later.
        int options_found = this.refresh_os_view.update_options();
        if (0 == options_found) {
            this.load_encrypted_partition_view();
            return;
        }

        this.stack.visible_child = this.refresh_os_view;
    }

    private void load_encrypted_partition_view() {
        if (this.encrypted_partition_view == null) {
            this.encrypted_partition_view = new EncryptedPartitionView();
            this.encrypted_partition_view.decrypt.connect((uuid) => {
                this.load_decrypt_view(uuid);
            });
            this.stack.add(this.encrypted_partition_view);
        }

        this.encrypted_partition_view.clear();

        this.encrypted_devices();

        Timeout.add(100, () => {
            if (this.searching_for_encrypted_devices) {
                return GLib.Source.CONTINUE;
            }

            if (encrypted.length == 0) {
                return GLib.Source.REMOVE;
            }

            foreach (var block in encrypted) {
                this.encrypted_partition_view.add_option(block);
            }

            this.stack.set_visible_child(this.encrypted_partition_view);

            return GLib.Source.REMOVE;
        });
    }

    private void load_try_install_view () {
        Configuration.get_default ().retain_old = false;
        if (this.try_install_view == null) {
            this.try_install_view = new TryInstallView ();
            this.stack.add (this.try_install_view);
        }

        this.try_install_view.previous_view = keyboard_layout_view;
        this.stack.visible_child = this.try_install_view;
        this.try_install_view.custom_step.connect (load_partitioning_view);
        this.try_install_view.next_step.connect (load_disk_view);
        this.try_install_view.refresh_step.connect (() => {
            this.os_search();
        });
    }

    private void set_check_view_visible (bool show) {
        if (show) {
            check_view.previous_view = stack.visible_child;
            stack.visible_child = check_view;
        } else if (check_view.previous_view != null) {
            stack.visible_child = check_view.previous_view;
            check_view.previous_view = null;
        }
    }

    private void load_check_view () {
        if (check_view != null) {
            check_view.destroy ();
        }

        check_view = new Installer.CheckView (minimum_disk_size);
        stack.add (check_view);

        check_view.status_changed.connect ((met_requirements) => {
            if (!check_ignored) {
                set_check_view_visible (!met_requirements);
            }
        });

        check_view.cancel.connect (() => {
            stack.visible_child = try_install_view;
            check_view.previous_view = null;
        });

        check_view.next_step.connect (() => {
            check_ignored = true;
            set_check_view_visible (false);
        });

        set_check_view_visible (!check_ignored && !check_view.check_requirements ());
    }

    private void load_disk_view () {
        if (disk_view == null) {
            disk_view = new DiskView ();
            disk_view.cancel.connect (() => this.load_try_install_view());
            disk_view.next_step.connect (() => load_user_view (disk_view, load_try_install_view, load_encrypt_view));

            stack.add (disk_view);
        }

        disk_view.previous_view = try_install_view;
        stack.visible_child = disk_view;
        disk_view.load.begin (minimum_disk_size);

        load_check_view ();
    }

    private void load_partitioning_view () {
        if (partitioning_view == null) {
            partitioning_view = new PartitioningView (minimum_disk_size);

            partitioning_view.cancel.connect (() => {
                stack.visible_child = try_install_view;
            });

            partitioning_view.next_step.connect (() => {
                unowned Configuration config = Configuration.get_default ();
                config.luks = (owned) partitioning_view.luks;
                config.mounts = (owned) partitioning_view.mounts;
                load_user_view (partitioning_view, load_try_install_view, load_progress_view);
            });

            stack.add (partitioning_view);
        }

        partitioning_view.previous_view = try_install_view;
        stack.visible_child = partitioning_view;
        load_check_view ();
    }

    private void load_encrypt_view () {
        if (encrypt_view == null) {
            encrypt_view = new EncryptView ();
            encrypt_view.previous_view = disk_view;
            stack.add (encrypt_view);
            encrypt_view.next_step.connect (() => load_progress_view ());
        }

        if (Configuration.get_default ().password != null) {
            encrypt_view.reuse_password.show();
        } else {
            encrypt_view.reuse_password.hide();
        }

        stack.visible_child = encrypt_view;
        encrypt_view.reset();
    }

    private void load_progress_view () {
        check_ignored = true;

        if (progress_view != null) {
            progress_view.destroy ();
        }

        progress_view = new ProgressView ();
        stack.add (progress_view);
        stack.visible_child = progress_view;

        progress_view.on_success.connect (() => {
            load_ok_view (progress_view.get_log ());
        });

        progress_view.on_error.connect (() => {
            load_error_view (progress_view.get_log ());
        });

        start_date = new DateTime.now_local ();
        end_date = null;

        if (progress_view.test_label != null) {
            progress_view.test_label.set_text (_("Test Mode") + " 0.00");
        }

        var time_source = GLib.Timeout.add (10, () => {
            end_date = new DateTime.now_local ();
            if (progress_view.test_label != null) {
                var time_span = end_date.difference (start_date);
                progress_view.test_label.set_text (_("Test Mode") + " %.2f".printf ((double) time_span / 1000000.0));
            }
            return GLib.Source.CONTINUE;
        });

        progress_view.on_success.connect (() => {
            end_date = new DateTime.now_local ();
            GLib.Source.remove (time_source);
        });

        progress_view.on_error.connect (() => {
            end_date = new DateTime.now_local ();
            GLib.Source.remove (time_source);
        });

        progress_view.start_installation ();
    }

    private void load_ok_view (string log) {
        if (success_view != null) {
            success_view.destroy ();
        }

        success_view = new SuccessView (log);
        stack.add (success_view);
        stack.visible_child = success_view;

        if (success_view.test_label != null && start_date != null && end_date != null) {
            var time_span = end_date.difference (start_date);
            success_view.test_label.set_text (_("Test Mode") + " %.2f".printf ((double) time_span / 1000000.0));
        }
    }

    private void load_error_view (string log) {
        if (error_view != null) {
            error_view.destroy ();
        }

        error_view = new ErrorView (log, minimum_disk_size);
        error_view.previous_view = try_install_view;
        stack.add (error_view);
        stack.visible_child = error_view;
    }

    public override void close () {}
}
