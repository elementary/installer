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

public class Installer.LanguageView : AbstractInstallerView {
    private Gtk.Button next_button;
    private Gtk.Label select_label;
    private Gtk.Stack select_stack;
    private int select_number = 0;
    private static Gee.LinkedList<string> preferred_langs;
    private uint lang_timeout = 0U;
    private VariantWidget lang_variant_widget;

    public LanguageView () {
        lang_timeout = GLib.Timeout.add_seconds (3, timeout);
    }

    ~LanguageView () {
        if (lang_timeout > 0U) {
            GLib.Source.remove (lang_timeout);
        }
    }

    static construct {
        preferred_langs = new Gee.LinkedList<string> ();
        preferred_langs.add_all_array (Build.PREFERRED_LANG_LIST.split (";"));
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-desktop-locale") {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        select_label = new Gtk.Label (null) {
            halign = CENTER,
            valign = START,
            wrap = true
        };

        select_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        select_stack.add_child (select_label);

        select_stack.notify["transition-running"].connect (() => {
            if (!select_stack.transition_running) {
                select_stack.remove (select_stack.get_visible_child ().get_prev_sibling ());
            }
        });

        lang_variant_widget = new VariantWidget (_("Languages"));

        lang_variant_widget.variant_listbox.set_sort_func ((Gtk.ListBoxSortFunc) CountryRow.compare);

        lang_variant_widget.variant_listbox.row_activated.connect (() => {
            next_button.activate ();
        });

        lang_variant_widget.main_listbox.set_sort_func ((Gtk.ListBoxSortFunc) LangRow.compare);

        lang_variant_widget.main_listbox.set_header_func ((row, before) => {
            row.set_header (null);
            if (!((LangRow)row).preferred_row) {
                if (before != null && ((LangRow)before).preferred_row) {
                    var separator = new Gtk.Separator (HORIZONTAL) {
                        margin_top = 3,
                        margin_end = 6,
                        margin_bottom = 3,
                        margin_start = 6
                    };

                    row.set_header (separator);
                }
            }
        });

        foreach (var lang_entry in LocaleHelper.get_lang_entries ().entries) {
            if (lang_entry.key in preferred_langs) {
                var pref_langrow = new LangRow (lang_entry.value);
                pref_langrow.preferred_row = true;
                lang_variant_widget.main_listbox.append (pref_langrow);
            }

            var langrow = new LangRow (lang_entry.value);
            lang_variant_widget.main_listbox.append (langrow);
        }

        next_button = new Gtk.Button.with_label (_("Select")) {
            sensitive = false
        };
        next_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        action_box_end.append (next_button);

        lang_variant_widget.main_listbox.row_selected.connect (row_selected);
        lang_variant_widget.main_listbox.select_row (lang_variant_widget.main_listbox.get_row_at_index (0));
        lang_variant_widget.main_listbox.row_activated.connect (row_activated);

        next_button.clicked.connect (() => {
            unowned Gtk.ListBoxRow row = lang_variant_widget.main_listbox.get_selected_row ();
            if (row != null) {
                var lang_entry = ((LangRow) row).lang_entry;
                string lang = lang_entry.get_code ();
                Environment.set_variable ("LANGUAGE", lang, true);
                unowned Configuration configuration = Configuration.get_default ();
                configuration.lang = lang;

                unowned Gtk.ListBoxRow crow = lang_variant_widget.variant_listbox.get_selected_row ();
                if (crow != null) {
                    LocaleHelper.CountryEntry country = ((CountryRow) crow).country_entry;
                    configuration.country = country.get_code ();
                } else if (lang_entry.countries.length == 0) {
                    configuration.country = null;
                } else {
                    row.activate ();
                    return;
                }

                if (configuration.country != null && configuration.country != "") {
                    lang += "_" + configuration.country;
                }

                if (!Installer.App.test_mode) {
                    set_demo_mode_language.begin (lang);
                }
            } else {
                warning ("next_button enabled when no language selected");
                next_button.sensitive = false;
                return;
            }

            next_step ();
        });

        lang_variant_widget.going_to_main.connect (() => {
            next_button.sensitive = false;
        });

        destroy.connect (() => {
            // We need to disconnect the signal otherwise it's called several time when destroying the window…
            lang_variant_widget.main_listbox.row_selected.disconnect (row_selected);
        });

        title_area.append (image);
        title_area.append (select_stack);

        content_area.append (lang_variant_widget);

        timeout ();
    }

    private async void set_demo_mode_language (string language) {
        string? locale;
        if (yield LocaleHelper.language2locale (language, out locale)) {
            if (locale == null) {
                return;
            }

            // Write the language to /etc/default/locale so it is picked up by guest (demo) sessions
            try {
                yield Daemon.get_default ().set_demo_mode_locale (locale);
            } catch (Error e) {
                warning ("Error writing default locale, language in demo mode may be incorrect: %s", e.message);
            }
        }

    }

    private void row_selected (Gtk.ListBoxRow? row) {
        lang_variant_widget.variant_listbox.row_selected.disconnect (variant_row_selected);
        lang_variant_widget.clear_variants ();
        lang_variant_widget.variant_listbox.row_selected.connect (variant_row_selected);

        var lang_entry = ((LangRow) row).lang_entry;

        var child = lang_variant_widget.main_listbox.get_first_child ();
        while (child != null) {
            if (child is LangRow) {
                var lang_row = (LangRow) child;
                if (lang_row.lang_entry.get_code () == lang_entry.get_code ()) {
                    lang_row.selected = true;
                } else {
                    lang_row.selected = false;
                }
            }

            child = child.get_next_sibling ();
        }

        next_button.sensitive = true;
    }

    private void variant_row_selected (Gtk.ListBoxRow? row) {
        unowned var country_entry = ((CountryRow) row).country_entry;

        var child = lang_variant_widget.variant_listbox.get_first_child ();
        while (child != null) {
            if (child is CountryRow) {
                unowned var country_row = (CountryRow) child;
                if (country_row.country_entry.alpha_2 == country_entry.alpha_2) {
                    country_row.selected = true;
                } else {
                    country_row.selected = false;
                }
            }

            child = child.get_next_sibling ();
        }

        next_button.sensitive = true;
    }

    private void row_activated (Gtk.ListBoxRow row) {
            var lang_entry = ((LangRow) row).lang_entry;
            var countries = lang_entry.countries;
            if (countries.length == 0) {
                next_button.sensitive = true;
                return;
            }

            var lang_code = lang_entry.get_code ();
            string? main_country = LocaleHelper.get_main_country (lang_code);

            lang_variant_widget.variant_listbox.row_selected.disconnect (variant_row_selected);
            lang_variant_widget.clear_variants ();
            lang_variant_widget.variant_listbox.row_selected.connect (variant_row_selected);
            foreach (var country in countries) {
                var country_row = new CountryRow (country);
                lang_variant_widget.variant_listbox.append (country_row);
                if (country.get_code () == main_country) {
                    lang_variant_widget.variant_listbox.select_row (country_row);
                }
            }

            if (main_country == null || lang_variant_widget.variant_listbox.get_selected_row () == null) {
                lang_variant_widget.variant_listbox.select_row (lang_variant_widget.variant_listbox.get_row_at_index (0));
            }

            Environment.set_variable ("LANGUAGE", lang_code, true);
            Intl.textdomain (Build.GETTEXT_PACKAGE);
            lang_variant_widget.show_variants (lang_entry.name);
    }

    private bool timeout () {
        var row = lang_variant_widget.main_listbox.get_row_at_index (select_number);
        if (row == null) {
            select_number = 0;
            row = lang_variant_widget.main_listbox.get_row_at_index (select_number);

            if (row == null) {
                lang_timeout = 0;
                return Source.REMOVE;
            }
        }

        unowned string label_text = LocaleHelper.lang_gettext (N_("Select a Language"), ((LangRow) row).lang_entry.get_code ());
        title = label_text;
        select_label = new Gtk.Label (label_text);
        select_stack.add_child (select_label);
        select_stack.set_visible_child (select_label);

        select_number++;
        return GLib.Source.CONTINUE;
    }

    public class LangRow : Gtk.ListBoxRow {
        private Gtk.Image image;
        public LocaleHelper.LangEntry lang_entry;
        public bool preferred_row { get; set; default=false; }

        private bool _selected;
        public bool selected {
            get {
                return _selected;
            }
            set {
                if (value) {
                    image.icon_name = "selection-checked";
                    image.tooltip_text = _("Currently active language");
                } else {
                    image.tooltip_text = "";
                    image.clear ();
                }
                _selected = value;
            }
        }

        public LangRow (LocaleHelper.LangEntry lang_entry) {
            this.lang_entry = lang_entry;

            image = new Gtk.Image () {
                halign = END,
                hexpand = true
            };

            var label = new Gtk.Label (lang_entry.name) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0
            };
            label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

            var box = new Gtk.Box (HORIZONTAL, 6) {
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6
            };
            box.append (label);
            box.append (image);

            child = box;
        }

        public static int compare (LangRow langrow1, LangRow langrow2) {
            if (langrow1.preferred_row && langrow2.preferred_row == false) {
                return -1;
            } else if (langrow2.preferred_row && langrow1.preferred_row == false) {
                return 1;
            } else if (langrow1.preferred_row && langrow2.preferred_row) {
                return preferred_langs.index_of (langrow1.lang_entry.get_code ()) - preferred_langs.index_of (langrow2.lang_entry.get_code ());
            }

            return langrow1.lang_entry.name.collate (langrow2.lang_entry.name);
        }
    }

    public class CountryRow : Gtk.ListBoxRow {
        public LocaleHelper.CountryEntry country_entry;
        private Gtk.Image image;

        private bool _selected;
        public bool selected {
            get {
                return _selected;
            }
            set {
                if (value) {
                    image.icon_name = "selection-checked";
                    image.tooltip_text = _("Currently active language");
                } else {
                    image.tooltip_text = "";
                    image.clear ();
                }
                _selected = value;
            }
        }

        public CountryRow (LocaleHelper.CountryEntry country_entry) {
            this.country_entry = country_entry;

            image = new Gtk.Image () {
                halign = END,
                hexpand = true
            };

            var label = new Gtk.Label (country_entry.name) {
                ellipsize = END,
                xalign = 0
            };
            label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

            var box = new Gtk.Box (HORIZONTAL, 6) {
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6
            };
            box.append (label);
            box.append (image);

            child = box;
        }

        public static int compare (CountryRow countryrow1, CountryRow countryrow2) {
            return countryrow1.country_entry.name.collate (countryrow2.country_entry.name);
        }
    }
}
