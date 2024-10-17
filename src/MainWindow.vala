/*-
 * Copyright 2016-2023 elementary, Inc. (https://elementary.io)
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

[DBus (name = "org.freedesktop.UPower")]
public interface UPower : GLib.Object {
    public abstract bool on_battery { owned get; set; }
}

public class Installer.MainWindow : Gtk.ApplicationWindow, PantheonWayland.ExtendedBehavior {
    // We have to do it step by step because the vala compiler has overflows with big numbers.
    private const uint64 ONE_GB = 1000 * 1000 * 1000;
    // Minimum 15 GB
    private const uint64 MINIMUM_SPACE = 15 * ONE_GB;

    private Adw.NavigationView navigation_view;
    private LanguageView language_view;
    private TryInstallView try_install_view;
    private KeyboardLayoutView keyboard_layout_view;
    private bool check_ignored = false;
    private uint orca_timeout_id = 0;

    construct {
        language_view = new LanguageView ();

        navigation_view = new Adw.NavigationView ();
        navigation_view.add (language_view);

        child = navigation_view;
        titlebar = new Gtk.Grid () { visible = false };

        var back_action = new SimpleAction ("back", null);
        back_action.activate.connect (() => {
            navigation_view.pop ();
        });

        add_action (back_action);

        language_view.next_step.connect (() => {
            // Don't prompt for screen reader if we're able to navigate without it
            if (orca_timeout_id != 0) {
                Source.remove (orca_timeout_id);
            }

            load_keyboard_view ();
        });

        var mediakeys_settings = new Settings ("org.gnome.settings-daemon.plugins.media-keys");
        var a11y_settings = new Settings ("org.gnome.desktop.a11y.applications");

        orca_timeout_id = Timeout.add_seconds (10, () => {
            orca_timeout_id = 0;

            if (a11y_settings.get_boolean ("screen-reader-enabled")) {
                return Source.REMOVE;
            }

            var shortcut_string = Granite.accel_to_string (
                mediakeys_settings.get_strv ("screenreader")[0]
            );

            // Espeak can't read ⌘
            shortcut_string = shortcut_string.replace ("⌘", "Super");

            var orca_prompt = "Screen reader can be turned on with the keyboard shorcut %s".printf (shortcut_string);

            try {
                Process.spawn_command_line_async ("espeak '%s'".printf (orca_prompt));
            } catch (SpawnError e) {
                critical ("Couldn't read Orca prompt: %s", e.message);
            }

            return Source.REMOVE;
        });

        child.realize.connect (() => {
            connect_to_shell ();
            make_centered ();
        });
    }

    private void load_keyboard_view () {
        keyboard_layout_view = new KeyboardLayoutView ();
        try_install_view = new TryInstallView ();

        navigation_view.push (keyboard_layout_view);

        keyboard_layout_view.next_step.connect (() => {
            navigation_view.push (try_install_view);
        });

        try_install_view.custom_step.connect (() => {
            var check_view = load_check_view ();
            if (check_view == null) {
                load_partitioning_view ();
            } else {
                check_view.next_step.connect (() => {
                    load_partitioning_view ();
                });
            };
        });

        try_install_view.next_step.connect (() => {
            var check_view = load_check_view ();
            if (check_view == null) {
                load_disk_view ();
            } else {
                check_view.next_step.connect (() => {
                    load_disk_view ();
                });
            };
        });
    }

    private void load_disk_view () {
        var disk_view = new DiskView ();
        navigation_view.push (disk_view);

        disk_view.load.begin (MINIMUM_SPACE);
        disk_view.next_step.connect (() => load_encrypt_view ());
    }

    private Installer.CheckView? load_check_view () {
        if (check_ignored) {
            return null;
        }

        var check_view = new Installer.CheckView ();
        if (check_view.has_messages) {
            check_view.next_step.connect (() => {
                check_ignored = true;
            });

            navigation_view.push (check_view);

            return check_view;
        }

        return null;
    }

    private void load_encrypt_view () {
        var encrypt_view = new EncryptView ();
        encrypt_view.next_step.connect (load_drivers_view);

        navigation_view.push (encrypt_view);
    }

    private void load_partitioning_view () {
        var partitioning_view = new PartitioningView (MINIMUM_SPACE);
        navigation_view.push (partitioning_view);

        partitioning_view.next_step.connect (() => {
            unowned Configuration config = Configuration.get_default ();
            config.luks = (owned) partitioning_view.luks;
            config.mounts = (owned) partitioning_view.mounts;
            load_drivers_view ();
        });
    }

    private void load_drivers_view () {
        var drivers_view = new DriversView ();
        drivers_view.next_step.connect (() => load_progress_view ());

        navigation_view.push (drivers_view);
    }

    private void load_progress_view () {
        var progress_view = new ProgressView ();

        progress_view.on_success.connect (() => {
            var success_view = new SuccessView ();
            navigation_view.push (success_view);

            success_view.shown.connect (() => {
                 navigation_view.replace ({ success_view });
            });
        });

        progress_view.on_error.connect (() => {
            load_error_view (progress_view.get_log ());
        });

        progress_view.shown.connect (() => {
            navigation_view.replace ({ progress_view });
        });

        navigation_view.push (progress_view);
        progress_view.start_installation ();
    }

    private void load_error_view (string log) {
        var error_view = new ErrorView (log);

        error_view.retry_install.connect (() => {
            navigation_view.replace ({
                language_view,
                keyboard_layout_view,
                try_install_view,
                error_view
            });
            navigation_view.pop ();
        });

        error_view.shown.connect (() => {
             navigation_view.replace ({ error_view });
        });

        navigation_view.push (error_view);
    }
}
