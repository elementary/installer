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

    public Configuration.from_string (string data) throws GLib.Error {
        _config = (Configuration) Json.gobject_from_data (typeof (Configuration), data);
    }

    public string lang { get; set; }
    public string? country { get; set; default = null; }
    public string keyboard_layout { get; set; }
    public string? keyboard_variant { get; set; default = null; }
    public string? encryption_password { get; set; default = null; }
    public string hostname { get; set; default = Utils.get_hostname (); }
    public string disk { get; set; }
    public Gee.ArrayList<Installer.Mount>? mounts { get; set; default = null; }
    public Gee.ArrayList<InstallerDaemon.LuksCredentials?>? luks { get; set; default = null; }
}
