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
        notification.set_body (_("Installation will not succeed if this device loses power."));
        notification.set_icon (new ThemedIcon ("battery-ac-adapter"));
        notification.set_priority (NotificationPriority.URGENT);

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
    // When the installer starts on a live iso session, LANG is set to C.UTF-8, which causes gettext to ignore the
    // LANGUAGE variable. To enable runtime language switching, we need to set LANG to something other than C.UTF-8. See:
    // https://github.com/autotools-mirror/gettext/blob/8f089a25a48a2855e2ca9c700984f4dc514cfcb6/gettext-runtime/intl/dcigettext.c#L1509-L1525
    var current_lang = Environment.get_variable ("LANG");
    if (current_lang == null || current_lang.has_prefix ("C.")) {
        Environment.set_variable ("LANG", "en_US.UTF-8", true);
    }

    GLib.Intl.setlocale (LocaleCategory.ALL, "");
    GLib.Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.LOCALEDIR);
    GLib.Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
    GLib.Intl.textdomain (Build.GETTEXT_PACKAGE);

    return new Installer.App ().run (args);
}
