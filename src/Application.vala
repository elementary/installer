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
    public const OptionEntry[] INSTALLER_OPTIONS =  {
        { "test", 't', 0, OptionArg.NONE, out test_mode, "Non-destructive test mode", null},
        { null }
    };
    
    public static bool test_mode;

    construct {
        application_id = "io.elementary.installer";
        flags = ApplicationFlags.FLAGS_NONE;
        Intl.setlocale (LocaleCategory.ALL, "");
        add_main_option_entries (INSTALLER_OPTIONS);
    }

    public override void activate () {
        var window = new MainWindow ();
        window.show_all ();
        this.add_window (window);

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("io/elementary/installer/application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}

public static int main (string[] args) {
    var application = new Installer.App ();
    return application.run (args);
}

