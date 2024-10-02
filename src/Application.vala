/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2016-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Installer.App : Gtk.Application {
    public const OptionEntry[] INSTALLER_OPTIONS = {
        { "test", 't', 0, OptionArg.NONE, out test_mode, "Non-destructive test mode", null},
        { null }
    };

    public static bool test_mode;

    public App () {
        Object (
            application_id: "io.elementary.installer",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        GLib.Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (application_id, Build.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (application_id, "UTF-8");
        GLib.Intl.textdomain (application_id);

        add_main_option_entries (INSTALLER_OPTIONS);
    }

    public override void startup () {
        base.startup ();

        Granite.init ();

        try {
            UPower upower = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.UPower", "/org/freedesktop/UPower", GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES);

            send_withdraw_battery_notification (upower.on_battery);

            ((DBusProxy) upower).g_properties_changed.connect ((changed, invalid) => {
                var _on_battery = changed.lookup_value ("OnBattery", GLib.VariantType.BOOLEAN);
                if (_on_battery != null) {
                    send_withdraw_battery_notification (upower.on_battery);
                }
            });
        } catch (Error e) {
            critical ("Can't connect to UPower; unable to send battery notifications: %s", e.message);
        }
    }

    private void send_withdraw_battery_notification (bool on_battery) {
        if (!on_battery) {
            withdraw_notification ("on-battery");
            return;
        }

        var notification = new GLib.Notification (_("Connect to a Power Source"));
        notification.set_body (_("Your device is running on battery power. It's recommended to be plugged in while installing."));
        notification.set_icon (new ThemedIcon ("battery-ac-adapter"));
        notification.set_priority (NotificationPriority.HIGH);

        send_notification ("on-battery", notification);
    }

    public override void activate () {
        var window = new MainWindow () {
            deletable = false,
            default_height = 600,
            default_width = 850,
            icon_name = application_id,
            title = _("Install %s").printf (Utils.get_pretty_name ())
        };
        window.present ();
        add_window (window);

        inhibit (
            get_active_window (),
            Gtk.ApplicationInhibitFlags.IDLE | Gtk.ApplicationInhibitFlags.SUSPEND,
            _("operating system is being installed")
        );
    }
}

public static int main (string[] args) {
    return new Installer.App ().run (args);
}
