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

public class Installer.LanguageView : Gtk.Grid {
    Gtk.Label select_label;
    public LanguageView () {
        
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;

        select_label = new Gtk.Label (_("Select a Language"));
        select_label.get_style_context ().add_class ("h1");
        select_label.halign = Gtk.Align.CENTER;
        select_label.margin = 12;
        select_label.margin_top = 0;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        var list_box = new Gtk.ListBox ();
        list_box.set_sort_func ((row1, row2) => {
            return ((LangRow) row1).lang.collate (((LangRow) row2).lang);
        });
        scrolled.add (list_box);
        scrolled.expand = true;

        var current_lang = Environment.get_variable ("LANGUAGE");
        foreach (var lang in load_languagelist ()) {
            Environment.set_variable ("LANGUAGE", lang, true);
            Intl.textdomain ("pantheon-installer");
            var langrow = new LangRow (lang);
            list_box.add (langrow);
        }

        if (current_lang != null) {
            Environment.set_variable ("LANGUAGE", current_lang, true);
        } else {
            Environment.unset_variable ("LANGUAGE");
        }

        add (select_label);
        add (scrolled);
    }

    Gee.HashSet<string> load_languagelist () {
        var file = File.new_for_path ("/usr/share/i18n/SUPPORTED");
        var lang_supported = new Gee.HashSet<string> ();
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            while ((line = dis.read_line (null)) != null) {
                var first_part = line.split (" ", 2)[0];
                var first_part2 = first_part.split (".", 2)[0];
                var lang_familly_part = first_part2.split ("_", 2)[0];
                lang_supported.add (lang_familly_part);
            }
        } catch (Error e) {
            error ("%s", e.message);
        }

        return lang_supported;
    }

    public class LangRow : Gtk.ListBoxRow {
        public string lang;
        public LangRow (string lang) {
            this.lang = lang;
            var str = _("Use English");
            if (str == "Use English" && lang != "en") {
                str = "%s (%s)".printf (str, lang);
            }

            var label = new Gtk.Label (str);
            label.margin = 6;
            label.get_style_context ().add_class ("h3");
            label.halign = Gtk.Align.CENTER;
            add (label);
        }
    }
}
