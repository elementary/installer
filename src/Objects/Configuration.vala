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
            _config.load_from_recovery();
        }

        return _config;
    }

    public string lang { get; set; }
    public string? country { get; set; default = null; }
    public string? cached_locale { get; set; default = null; }
    public string keyboard_layout { get; set; }
    public string? keyboard_variant { get; set; default = null; }
    public string? encryption_password { get; set; default = null; }
    public string? realname { get; set; default = null; }
    public string? username { get; set; default = null; }
    public string? password { get; set; default = null; }
    public string? profile_icon { get; set; default = null; }
    public string disk { get; set; }
    public bool recovery { get; set; default = false; }
    public bool retain_home { get; set; default = false; }
    public bool retain_old { get; set; default = false; }
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

    /**
     * Load values from the recovery environment, if there are values to load.
     **/
    public void load_from_recovery() {
        var opts = InstallOptions.get_default ();
        unowned Distinst.InstallOptions options = opts.get_updated_options ();
        var recovery = options.get_recovery_option ();
        if (null != recovery) {
            var lang = Utils.string_from_utf8 (recovery.get_language ());
            var lang_parts = lang.split ("_", 2);
            this.lang = lang_parts[0];
            if (lang_parts.length >= 2) {
                var country_parts = lang_parts[1].split (".", 2);
                this.country = country_parts[0];
            }

            this.keyboard_layout = Utils.string_from_utf8 (recovery.get_kbd_layout ());

            unowned uint8[]? variant = recovery.get_kbd_variant ();
            if (null != variant) {
                this.keyboard_variant = Utils.string_from_utf8 (variant);
            }
        }
    }
}
