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
    switch(level) {
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
            log_func(Distinst.LogLevel.ERROR, _("Unable to set the Distinst log callback"));
        } else {
            log_func(Distinst.LogLevel.INFO, _("Starting installation"));
        }
    }

    /**
     * Workaround for https://gitlab.gnome.org/GNOME/gtk/issues/1161
     */
    private string wrap (Distinst.LogLevel level, string message, int limit) {
        string[] words = message.split_set (" \t\n");
        string output = level_name (level) + ": ";
        int prefix = output.length;
        int actual_limit = limit - output.length;

        if (words.length == 0) {
            return output + "\n";
        }

        string tab = "";
        for (int i = 0; i < prefix; i++) {
            tab += " ";
        }

        int chars = words[0].length;
        output += words[0];

        for (int i = 1; i < words.length; i++) {
            unowned string word = words[i];
            if (chars + word.length >= actual_limit) {
                chars = word.length;
                output += "\n" + tab + word;
            } else {
                chars += word.length + 1;
                output += " " + word;
            }
        }

        return output + "\n";
    }

    private void log_func (Distinst.LogLevel level, string message) {
        string msg = wrap (level, message, 80);
        stdout.printf ("log: %s", msg);
        Idle.add (() => {
            Gtk.TextIter end_iter;
            buffer.get_end_iter (out end_iter);
            buffer.insert (ref end_iter, msg, msg.length);
            return GLib.Source.REMOVE;
        });
    }
}
