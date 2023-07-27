/*-
 * Copyright 2016-2020 elementary, Inc. (https://elementary.io)
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

public class Installer.MainWindow : Hdy.Window {
    // We have to do it step by step because the vala compiler has overflows with big numbers.
    private const uint64 ONE_GB = 1000 * 1000 * 1000;
    // Minimum 15 GB
    private const uint64 MINIMUM_SPACE = 15 * ONE_GB;

    private Gtk.Label infobar_label;
    private Hdy.Deck deck;
    private LanguageView language_view;
    private KeyboardLayoutView keyboard_layout_view;
    private TryInstallView try_install_view;
    private Installer.CheckView check_view;
    private DiskView disk_view;
    private PartitioningView partitioning_view;
    private DriversView drivers_view;
    private ProgressView progress_view;
    private SuccessView success_view;
    private EncryptView encrypt_view;
    private ErrorView error_view;
    private bool check_ignored = false;
    private uint orca_timeout_id = 0;

    construct {
        language_view = new LanguageView ();

        deck = new Hdy.Deck () {
            can_swipe_back = true
        };
        deck.add (language_view);

        infobar_label = new Gtk.Label ("") {
            use_markup = true
        };
        set_infobar_string ();

        var battery_infobar = new Gtk.InfoBar () {
            message_type = Gtk.MessageType.WARNING,
            margin_end = 7,
            margin_bottom = 7,
            margin_start = 7,
            show_close_button = true,
            halign = Gtk.Align.START, // Can't cover action area; need to select language
            valign = Gtk.Align.END
        };
        battery_infobar.get_content_area ().add (infobar_label);
        battery_infobar.get_style_context ().add_class ("frame");

        var overlay = new Gtk.Overlay () {
            child = deck
        };
        overlay.add_overlay (battery_infobar);

        child = overlay;

        language_view.next_step.connect (() => {
            // Don't prompt for screen reader if we're able to navigate without it
            if (orca_timeout_id != 0) {
                Source.remove (orca_timeout_id);
            }

            // We need to rebuild the views to reflect language changes
            while (deck.get_adjacent_child (FORWARD) != null) {
                deck.remove (deck.get_adjacent_child (FORWARD));
            }

            // Reset when language selection changes
            set_infobar_string ();
            load_keyboard_view ();
        });

        try {
            UPower upower = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.UPower", "/org/freedesktop/UPower", GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES);

            battery_infobar.revealed = upower.on_battery;

            ((DBusProxy) upower).g_properties_changed.connect ((changed, invalid) => {
                var _on_battery = changed.lookup_value ("OnBattery", GLib.VariantType.BOOLEAN);
                if (_on_battery != null) {
                    battery_infobar.revealed = upower.on_battery;
                }
            });
        } catch (Error e) {
            warning (e.message);
            battery_infobar.revealed = false;
        }

        battery_infobar.response.connect (() => {
            battery_infobar.revealed = false;
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
    }

    private void load_keyboard_view () {
        keyboard_layout_view = new KeyboardLayoutView ();
        try_install_view = new TryInstallView ();

        deck.add (keyboard_layout_view);
        deck.add (try_install_view);

        deck.visible_child = keyboard_layout_view;

        try_install_view.custom_step.connect (() => load_partitioning_view ());
        try_install_view.next_step.connect (() => load_disk_view ());
    }

    private void set_check_view_visible (bool show) {
        if (show) {
            deck.visible_child = check_view;
        } else {
            deck.navigate (Hdy.NavigationDirection.BACK);
        }
    }

    private void load_check_view () {
        check_view = new Installer.CheckView ();
        deck.add (check_view);

        check_view.cancel.connect (() => {
            deck.visible_child = try_install_view;
            check_view.destroy ();
        });

        check_view.next_step.connect (() => {
            check_ignored = true;
            set_check_view_visible (false);
        });

        set_check_view_visible (!check_ignored && check_view.has_messages);
    }

    private void load_encrypt_view () {
        encrypt_view = new EncryptView ();
        deck.add (encrypt_view);
        deck.visible_child = encrypt_view;

        encrypt_view.cancel.connect (() => {
            deck.visible_child = try_install_view;
        });

        encrypt_view.next_step.connect (() => {
            load_drivers_view ();
        });
    }

    private void load_disk_view () {
        disk_view = new DiskView ();
        deck.add (disk_view);
        deck.visible_child = disk_view;
        disk_view.load.begin (MINIMUM_SPACE);

        load_check_view ();

        disk_view.cancel.connect (() => {
            deck.visible_child = try_install_view;
        });

        disk_view.next_step.connect (() => load_encrypt_view ());
    }

    private void load_partitioning_view () {
        if (partitioning_view != null) {
            partitioning_view.destroy ();
        }

        partitioning_view = new PartitioningView (MINIMUM_SPACE);

        deck.add (partitioning_view);
        deck.visible_child = partitioning_view;

        partitioning_view.next_step.connect (() => {
            unowned Configuration config = Configuration.get_default ();
            config.luks = (owned) partitioning_view.luks;
            config.mounts = (owned) partitioning_view.mounts;
            load_drivers_view ();
        });
    }

    private void load_drivers_view () {
        if (drivers_view != null) {
            drivers_view.destroy ();
        }

        drivers_view = new DriversView ();

        deck.add (drivers_view);
        deck.visible_child = drivers_view;

        drivers_view.next_step.connect (() => load_progress_view ());
    }

    private void load_progress_view () {
        progress_view = new ProgressView ();

        deck.add (progress_view);
        deck.visible_child = progress_view;
        deck.can_swipe_back = false;

        progress_view.on_success.connect (() => load_success_view ());

        progress_view.on_error.connect (() => {
            load_error_view (progress_view.get_log ());
            deck.can_swipe_back = true;
        });
        progress_view.start_installation ();
    }

    private void load_success_view () {
        success_view = new SuccessView ();
        deck.add (success_view);
        deck.visible_child = success_view;
    }

    private void load_error_view (string log) {
        error_view = new ErrorView (log);
        deck.add (error_view);
        deck.visible_child = error_view;
    }

    private void set_infobar_string () {
        var infobar_string = "%s\n%s".printf (
            _("Connect to a Power Source"),
            Granite.TOOLTIP_SECONDARY_TEXT_MARKUP.printf (_("Your device is running on battery power. It's recommended to be plugged in while installing."))
        );

        infobar_label.label = infobar_string;
    }
}
