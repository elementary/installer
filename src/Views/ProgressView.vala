/*-
 * Copyright 2017-2021 elementary, Inc. (https://elementary.io)
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
        var style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("io/elementary/installer/ProgressView.css");

        var logo_icon_name = Environment.get_os_info ("LOGO");
        if (logo_icon_name == "" || logo_icon_name == null) {
            logo_icon_name = "distributor-logo";
        }

        var logo = new Hdy.Avatar (192, "", false) {
            // In case the wallpaper can't be loaded, we don't want an icon or text
            icon_name = "invalid-icon-name",
            // We need this for the shadow to not get clipped by Gtk.Overlay
            margin = 6
        };
        logo.loadable_icon = new FileIcon (File.new_for_path ("/usr/share/backgrounds/elementaryos-default"));
        logo.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var icon = new Gtk.Image () {
            icon_name = logo_icon_name + "-symbolic",
            pixel_size = 192
        };

        unowned var icon_style_context = icon.get_style_context ();
        icon_style_context.add_class ("logo");
        icon_style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var logo_overlay = new Gtk.Overlay () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        logo_overlay.add (logo);
        logo_overlay.add_overlay (icon);

        unowned LogHelper log_helper = LogHelper.get_default ();
        terminal_view = new Installer.Terminal (log_helper.buffer);

        var logo_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.OVER_UP_DOWN
        };
        logo_stack.add (logo_overlay);
        logo_stack.add (terminal_view);

        var terminal_button = new Gtk.ToggleButton () {
            halign = Gtk.Align.END,
            image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            tooltip_text = _("Show log")
        };
        terminal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        progressbar_label = new Gtk.Label (null) {
            use_markup = true,
            xalign = 0
        };
        progressbar_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        progressbar = new Gtk.ProgressBar () {
            hexpand = true
        };

        content_area.margin_end = 12;
        content_area.margin_start = 12;
        content_area.attach (logo_stack, 0, 0, 2);
        content_area.attach (progressbar_label, 0, 1);
        content_area.attach (terminal_button, 1, 1);
        content_area.attach (progressbar, 0, 2, 2);

        terminal_button.toggled.connect (() => {
            if (terminal_button.active) {
                terminal_button.tooltip_text = _("Hide log");
                logo_stack.visible_child = terminal_view;
                terminal_view.attempt_scroll ();
            } else {
                terminal_button.tooltip_text = _("Show log");
                logo_stack.visible_child = logo_overlay;
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
            real_installation.begin ();
        }
    }

    public async void real_installation () {
        unowned LogHelper log_helper = LogHelper.get_default ();
        unowned Installer.Daemon daemon = Installer.Daemon.get_default ();
        daemon.on_error.connect (installation_error_callback);
        daemon.on_status.connect (installation_status_callback);
        daemon.on_log_message.connect (log_helper.log_func);

        var config = InstallerDaemon.InstallConfig ();
        config.flags = Distinst.MODIFY_BOOT_ORDER;
        config.lang = "en_US.UTF-8";

        unowned Configuration current_config = Configuration.get_default ();

        config.hostname = current_config.hostname;

        debug ("language: %s\n", current_config.lang);
        string lang = current_config.lang;
        if (current_config.country != null && current_config.country != "") {
            debug ("country: %s\n", current_config.country);
            lang += "_" + current_config.country;
        }

        string? locale;
        if (yield LocaleHelper.language2locale (lang, out locale)) {
            if (locale != null) {
                config.lang = locale;
            }
        }

        config.keyboard_layout = current_config.keyboard_layout;
        config.keyboard_variant = current_config.keyboard_variant ?? "";

        if (current_config.mounts == null) {
            try {
                yield daemon.install_with_default_disk_layout (
                    config,
                    current_config.disk,
                    current_config.encryption_password != null,
                    current_config.encryption_password ?? ""
                );
            } catch (Error e) {
                log_helper.log_func (Distinst.LogLevel.ERROR, e.message);
                on_error ();
            }
        } else {
            InstallerDaemon.Mount[] mounts = {};
            foreach (Installer.Mount m in current_config.mounts) {
                mounts += InstallerDaemon.Mount () {
                    partition_path = m.partition_path,
                    parent_disk = m.parent_disk,
                    mount_point = m.mount_point,
                    sectors = m.sectors,
                    filesystem = m.filesystem,
                    flags = m.flags
                };
            }

            InstallerDaemon.LuksCredentials[] creds = {};
            foreach (InstallerDaemon.LuksCredentials? cred in current_config.luks) {
                if (cred != null) {
                    creds += cred;
                }
            }

            try {
                yield daemon.install_with_custom_disk_layout (config, mounts, creds);
            } catch (Error e) {
                log_helper.log_func (Distinst.LogLevel.ERROR, e.message);
                on_error ();
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
            GLib.Thread.usleep (100000);
        }
    }

    private void installation_status_callback (Distinst.Status status) {
        Idle.add (() => {
            if (status.percent == 100 && status.step == Distinst.Step.BOOTLOADER) {
                on_success ();
                return GLib.Source.REMOVE;
            }

            string step_string = "";
            double fraction = ((double) status.percent) / (100.0 * NUM_STEP);
            switch (status.step) {
                case Distinst.Step.PARTITION:
                    ///TRANSLATORS: The current step of the installer back-end
                    step_string = _("Partitioning Drive");
                    break;
                case Distinst.Step.EXTRACT:
                    fraction += 2 * (1.0 / NUM_STEP);
                    ///TRANSLATORS: The current step of the installer back-end
                    step_string = _("Extracting Files");
                    break;
                case Distinst.Step.CONFIGURE:
                    fraction += 3 * (1.0 / NUM_STEP);
                    ///TRANSLATORS: The current step of the installer back-end
                    step_string = _("Configuring the System");
                    break;
                case Distinst.Step.BOOTLOADER:
                    fraction += 4 * (1.0 / NUM_STEP);
                    ///TRANSLATORS: The current step of the installer back-end
                    step_string = _("Finishing the Installation");
                    break;
            }

            progressbar_label.label = "<span font-features='tnum'>%s (%d%%)</span>".printf (step_string, status.percent);
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
