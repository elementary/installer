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

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("io/elementary/installer/Application.css");

        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        var css_fallback = new Gtk.CssProvider ();
        css_fallback.load_from_resource ("io/elementary/installer/disk-bar-fallback.css");
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            css_fallback,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    public override void activate () {
        var window = new MainWindow () {
            deletable = false,
            default_height = 600,
            default_width = 850,
            icon_name = application_id,
            title = _("Install %s").printf (Utils.get_pretty_name ())
        };
        window.show_all ();
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
