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

public class Installer.App : Granite.Application {
    construct {
        application_id = "io.elementary.installer";
        flags = ApplicationFlags.FLAGS_NONE;

        Intl.setlocale (LocaleCategory.ALL, "");

        program_name = _("Installer");
        build_version = Build.VERSION;
        app_years = "2016";
        app_icon = "system-os-install";

        app_launcher = "io.elementary.installer.desktop";
        main_url = "https://launchpad.net/pantheon-installer";
        bug_url = "https://bugs.launchpad.net/pantheon-installer";
        help_url = "https://answers.launchpad.net/pantheon-installer"; 
        translate_url = "https://translations.launchpad.net/pantheon-installer";
        about_authors = { "Corentin Noël <corentin@elementary.io>" };
        about_comments = "";
        about_translators = _("translator-credits");
        about_license_type = Gtk.License.GPL_3_0;
    }

    public override void activate () {
        var window = new MainWindow ();
        window.show_all ();
        this.add_window (window);
    }
}

public static int main (string[] args) {
    var application = new Installer.App ();
    return application.run (args);
}

