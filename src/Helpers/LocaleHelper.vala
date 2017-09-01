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

namespace LocaleHelper {
    public static Gee.HashMap<string, string> load_languagelist () {
        var langlist = new Gee.HashMap<string, string> ();

        unowned Xml.Doc* doc = Xml.Parser.read_file ("/usr/share/xml/iso-codes/iso_639_3.xml");
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
        } else {
            var current_lang = Environment.get_variable ("LANGUAGE");
            foreach (unowned string lang in Build.LANG_LIST.split (";")) {
                // We need to distinguish between pt and pt_BR
                if ("_" in lang) {
                    var parts = lang.split ("_", 2);
                    var name = get_iso_639_3_name (parts[0], root);
                    if (name != lang) {
                        Environment.set_variable ("LANGUAGE", lang, true);
                        Intl.textdomain ("pantheon-installer");
                        var country_name = get_country_name (parts[1]);
                        langlist.set (lang, "%s (%s)".printf (dgettext ("iso_639_3", name), dgettext ("iso_3166", country_name)));
                    }
                } else {
                    var name = get_iso_639_3_name (lang, root);
                    if (name != lang) {
                        Environment.set_variable ("LANGUAGE", lang, true);
                        Intl.textdomain ("pantheon-installer");
                        langlist.set (lang, dgettext ("iso_639_3", name));
                    }
                }
            }

            if (current_lang != null) {
                Environment.set_variable ("LANGUAGE", current_lang, true);
            } else {
                Environment.unset_variable ("LANGUAGE");
            }
        }

        return langlist;
    }

    public static string get_iso_639_3_name (string lang_code, Xml.Node* root) {
        for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                if (iter->name == "iso_639_3_entry") {
                    string? id = iter->get_prop ("id");
                    if (id != lang_code) {
                        id = iter->get_prop ("part1_code");
                    }

                    if (id == lang_code) {
                        return iter->get_prop ("name");
                    }
                }
            }
        }

        return lang_code;
    }

    public static string get_country_name (string country_code) {
        unowned Xml.Doc* doc = Xml.Parser.read_file ("/usr/share/xml/iso-codes/iso_3166.xml");
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
        } else {
            for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
                if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                    if (iter->name == "iso_3166_entry") {
                        string? id = iter->get_prop ("alpha_2_code");
                        if (id != country_code) {
                            id = iter->get_prop ("alpha_3_code");
                        }

                        if (id == country_code) {
                            var country_name = iter->get_prop ("name");
                            delete doc;
                            return country_name;
                        }
                    }
                }
            }
        }

        delete doc;
        return "";
    }
}
