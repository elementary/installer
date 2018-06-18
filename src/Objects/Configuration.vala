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

public class Configuration : GLib.Object {
    private static Configuration _config;
    public static unowned Configuration get_default () {
        if (_config == null) {
            _config = new Configuration ();
        }

        return _config;
    }

    public string lang { get; set; }
    public string? country { get; set; default = null; }
    public string keyboard_layout { get; set; }
    public string? keyboard_variant { get; set; default = null; }
    public string? encryption_password { get; set; default = null; }
    public string disk { get; set; }
    public Gee.ArrayList<Installer.Mount>? mounts { get; set; default = null; }
    public Gee.ArrayList<Installer.LuksCredentials>? luks { get; set; default = null; }

    /**
     * Uses distinst to attempt to get a default locale if no country is available.
     *
     * - If a country is provided, a locale will be generated without distinst's help.
     * - If distinst returns a null value, we will default to `en_US.UTF-8`.
     **/
    public string get_locale () {
        if (country == null) {
            string? default = Distinst.locale_get_default (lang);
            if (default == null) {
                warning ("distinst could not generate a default locale for %s\n", lang);
                return "en_US.UTF-8";
            } else {
                return default;
            }
        } else if (country == "None") {
            return lang;
        }

        return lang + "_" + country + ".UTF-8";
    }
}
