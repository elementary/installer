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
    public class LangEntry {
        public string code;
        public string? name;
        public CountryEntry[] countries;
        public int preferred;

        public LangEntry () {
            countries = {};
        }

        public void add_country (CountryEntry country_entry) {
            var _countries = countries;
            _countries += country_entry;
            countries = _countries;
        }

        public unowned string get_code () {
            return code;
        }

        public void push_country_to_start (string country) {
            var i = 0;
            var found = false;
            foreach (var entry in countries) {
                if (country == entry.code) {
                    found = true;
                    break;
                }
                i += 1;
            }

            if (found) {
                var temp = countries[0];
                countries[0] = countries[i];
                countries[i] = temp;
            }
        }
    }

    public struct CountryEntry {
        public string code;
        public string? name;
    }

    private static Gee.HashMap<string, LangEntry> lang_entries;

    public static Gee.HashMap<string, LangEntry> get_lang_entries () {
        if (lang_entries == null) {
            lang_entries = new Gee.HashMap<string, LangEntry> ();

            foreach (var language in Distinst.locale_get_language_codes ()) {
                var lang_entry = new LangEntry () {
                    code = language,
                    name = Distinst.locale_get_language_name_translated (language)
                };

                foreach (var country in Distinst.locale_get_country_codes (language)) {
                    if (country == "None") {
                        lang_entry.add_country (CountryEntry () {
                            code = country,
                            name = country
                        });
                    } else {
                        lang_entry.add_country (CountryEntry () {
                            code = country,
                            name = Distinst.locale_get_country_name_translated (country, language)
                        });
                    }
                }

                var main = get_main_country (language);
                if (main != null) {
                    lang_entry.push_country_to_start (main);
                }

                lang_entries[language] = lang_entry;
            }
        }

        return lang_entries;
    }

    public static string? get_main_country (string lang_prefix) {
        uint8[]? main = Distinst.locale_get_main_country (lang_prefix);
        if (main != null) {
            return Utils.string_from_utf8 (main);
        }

        // We fallback to whatever is available in the lang list.
        var lang_prefixed = lang_prefix + "_";
        if (lang_prefixed in Build.LANG_LIST) {
            var parts = Build.LANG_LIST.split (lang_prefixed, 2);
            var country_part = parts[1].split (";", 2);
            return country_part[0];
        }

        return null;
    }
}
