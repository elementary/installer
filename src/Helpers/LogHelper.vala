// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
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
 */

public class LogHelper : GLib.Object {
    public const string DISTINST_LOG_DOMAIN = "io.elementary.installer.distinst";
    public Gtk.TextBuffer buffer { public get; construct; }

    private static LogHelper _instance;
    public static unowned LogHelper get_default () {
        if (_instance == null) {
            _instance = new LogHelper ();
        }

        return _instance;
    }

    construct {
        buffer = new Gtk.TextBuffer (null);
        if (Distinst.log (DISTINST_LOG_DOMAIN) != 0) {
            buffer.text = _("Unable to change the Distinst log domain name");
        } else {
            buffer.text = _("Starting installation\n");
        }

        GLib.Log.set_handler (DISTINST_LOG_DOMAIN, GLib.LogLevelFlags.FLAG_RECURSION|GLib.LogLevelFlags.FLAG_FATAL|GLib.LogLevelFlags.LEVEL_MASK, log_func);
    }

    private void log_func (string? log_domain, GLib.LogLevelFlags log_levels, string message) {
        buffer.text += message;
    }
}
