// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016–2018 elementary LLC. (https://elementary.io)
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

public class Installer.App : Gtk.Application {
    public const OptionEntry[] INSTALLER_OPTIONS = {
        { "test", 't', 0, OptionArg.NONE, out test_mode, "Non-destructive test mode", null},
        { null }
    };

    public static bool test_mode;

    private static Installer.App instance = null;

    construct {
        application_id = "io.elementary.installer";
        flags = ApplicationFlags.FLAGS_NONE;
        Intl.setlocale (LocaleCategory.ALL, "");
        add_main_option_entries (INSTALLER_OPTIONS);
        instance = this;
    }

    public static Installer.App get_instance () {
        assert (instance != null);

        return instance;
    }

    public override void activate () {
        DistinstIface distinst;

        try {
            distinst = Bus.get_proxy_sync(BusType.SYSTEM, "com.system76.Distinst", "/com/system76/Distinst", DBusProxyFlags.NONE);
        } catch (GLib.Error e) {
            stderr.printf ("could not locate Distinst DBus service: %s\n", e.message);
            return;
        }

        var window = new MainWindow (distinst);
        window.show_all ();
        this.add_window (window);

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("io/elementary/installer/application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var css_fallback = new Gtk.CssProvider ();
        css_fallback.load_from_resource ("io/elementary/installer/disk-bar-fallback.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_fallback, Gtk.STYLE_PROVIDER_PRIORITY_THEME);

        Inhibitor.get_instance ().inhibit ();
    }
}

public static int main (string[] args) {
    // Initialize distinst logging in advance.
    LogHelper.get_default();

    // Deactivates all LVM / LUKS devices before launching the UI.
    // This measure is to prevent possible mount, unmount, and file system conflicts.
    Distinst.deactivate_logical_devices ();

    var application = new Installer.App ();
    return application.run (args);
}
