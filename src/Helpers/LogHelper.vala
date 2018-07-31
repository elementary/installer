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

static string level_name (Distinst.LogLevel level) {
    switch (level) {
        case Distinst.LogLevel.TRACE:
            return "TRACE";
        case Distinst.LogLevel.DEBUG:
            return "DEBUG";
        case Distinst.LogLevel.INFO:
            return "INFO";
        case Distinst.LogLevel.WARN:
            return "WARN";
        case Distinst.LogLevel.ERROR:
            return "ERROR";
        default:
            return "UNKNOWN";
    }
}

public class LogHelper : GLib.Object {
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
        buffer.text = "";
        if (Distinst.log (log_func) != 0) {
            log_func (Distinst.LogLevel.ERROR, _("Unable to set the Distinst log callback"));
        } else {
            log_func (Distinst.LogLevel.INFO, _("Starting installation"));
        }
    }

    private void log_func (Distinst.LogLevel level, string message) {
        Idle.add (() => {
            Gtk.TextIter end_iter;
            buffer.get_end_iter (out end_iter);
            string new_line = "\n" + level_name (level) + ": " + message;
            buffer.insert (ref end_iter, new_line, new_line.length);
            return GLib.Source.REMOVE;
        });
    }
}
