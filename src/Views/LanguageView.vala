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
    public Gtk.Label select_label { get; construct; }
    public Gtk.Stack select_stack { get; construct; }
    Gtk.Button next_button;
    int select_number = 0;
    Gee.LinkedList<string> preferred_langs;

    private VariantWidget lang_variant_widget;

    public signal void next_step ();

    public LanguageView () {
        GLib.Timeout.add_seconds (3, timeout);

        var select_label = new Gtk.Label (null);
        select_label.halign = Gtk.Align.CENTER;
        select_label.wrap = true;

        var select_stack = new Gtk.Stack ();
        select_stack.get_style_context ().add_class ("h2");
        select_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        select_stack.add (select_label);
        select_stack.set_visible_child (select_label);
        select_stack.margin_bottom = 30;

        Object (
            artwork: "language",
            title_widget: (Gtk.Widget) select_stack,
            select_label: select_label,
            select_stack: select_stack
        );
    }

    construct {
        preferred_langs = new Gee.LinkedList<string> ();
        foreach (var lang in Build.PREFERRED_LANG_LIST.split (";")) {
            preferred_langs.add (lang);
        }

        var image = new Gtk.Image.from_icon_name ("preferences-desktop-locale", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        select_stack.notify["transition-running"].connect (() => {
            if (!select_stack.transition_running) {
                select_stack.get_children ().foreach ((child) => {
                    if (child != select_stack.get_visible_child ()) {
                        child.destroy ();
                    }
                });
            }
        });

        lang_variant_widget = new VariantWidget ();

        lang_variant_widget.main_listbox.set_sort_func ((row1, row2) => {
            var langrow1 = (LangRow) row1;
            var langrow2 = (LangRow) row2;
            if (langrow1.preferred_row && langrow2.preferred_row == false) {
                return -1;
            } else if (langrow2.preferred_row && langrow1.preferred_row == false) {
                return 1;
            } else if (langrow1.preferred_row && langrow2.preferred_row) {
                return preferred_langs.index_of (langrow1.lang_entry.get_code ()) - preferred_langs.index_of (langrow2.lang_entry.get_code ());
            }

            return langrow1.lang_entry.name.collate (langrow2.lang_entry.name);
        });

        lang_variant_widget.main_listbox.set_header_func ((row, before) => {
            row.set_header (null);
            if (!((LangRow)row).preferred_row) {
                if (before != null && ((LangRow)before).preferred_row) {
                    var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
                    separator.show_all ();
                    separator.margin = 3;
                    separator.margin_end = 6;
                    separator.margin_start = 6;
                    row.set_header (separator);
                }
            }
        });

        foreach (var lang_entry in LocaleHelper.get_lang_entries ().entries) {
            if (lang_entry.key in preferred_langs) {
                var pref_langrow = new LangRow (lang_entry.value);
                pref_langrow.preferred_row = true;
                lang_variant_widget.main_listbox.add (pref_langrow);
            }

            var langrow = new LangRow (lang_entry.value);
            lang_variant_widget.main_listbox.add (langrow);
        }

        next_button = new Gtk.Button.with_label (_("Select"));
        next_button.sensitive = false;
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (next_button);

        lang_variant_widget.main_listbox.row_selected.connect (row_selected);
        lang_variant_widget.main_listbox.select_row (lang_variant_widget.main_listbox.get_row_at_index (0));
        lang_variant_widget.main_listbox.row_activated.connect (row_activated);

        lang_variant_widget.key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.Return:
                    if (next_button.sensitive) {
                        next_button.clicked ();
                    }
                    return true;
                case Gdk.Key.Left:
                    if (event.state != Gdk.ModifierType.MOD1_MASK) {
                        break;
                    }
                case Gdk.Key.Escape:
                    lang_variant_widget.back_button.clicked ();
                    return true;
            }

            return false;
        });

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
                    string country = ((CountryRow) crow).country_entry.code;
                    configuration.country = country;
                } else if (lang_entry.countries.length == 0) {
                    configuration.country = null;
                } else {
                    row.activate ();
                    return;
                }
            } else {
                warning ("next_button enabled when no language selected");
                next_button.sensitive = false;
                return;
            }

            next_step ();
        });

        destroy.connect (() => {
            // We need to disconnect the signal otherwise it's called several time when destroying the window…
            lang_variant_widget.main_listbox.row_selected.disconnect (row_selected);
        });

        content_area.attach (lang_variant_widget, 1, 0, 1, 2);

        timeout ();
    }

    private void row_selected (Gtk.ListBoxRow? row) {
        var current_lang = Environment.get_variable ("LANGUAGE");
        var lang_entry = ((LangRow) row).lang_entry;
        Environment.set_variable ("LANGUAGE", lang_entry.get_code (), true);
        Intl.textdomain (Build.GETTEXT_PACKAGE);

        foreach (Gtk.Widget child in lang_variant_widget.main_listbox.get_children ()) {
            if (child is LangRow) {
                var lang_row = (LangRow) child;
                if (lang_row.lang_entry.get_code () == lang_entry.get_code ()) {
                    lang_row.selected = true;
                } else {
                    lang_row.selected = false;
                }
            }
        }

        if (current_lang != null) {
            Environment.set_variable ("LANGUAGE", current_lang, true);
        } else {
            Environment.unset_variable ("LANGUAGE");
        }

        next_button.sensitive = true;
    }

    private void variant_row_selected (Gtk.ListBoxRow? row) {
        if (row == null) return;
        var country_entry = ((CountryRow) row).country_entry;
        foreach (Gtk.Widget child in lang_variant_widget.variant_listbox.get_children ()) {
            if (child is CountryRow) {
                var country_row = (CountryRow) child;
                if (country_row.country_entry.code == country_entry.code) {
                    country_row.selected = true;
                } else {
                    country_row.selected = false;
                }
            }
        }
    }

    private void row_activated (Gtk.ListBoxRow row) {
            var lang_entry = ((LangRow) row).lang_entry;
            var countries = lang_entry.countries;
            if (countries.length == 0) {
                return;
            }

            lang_variant_widget.variant_listbox.row_selected.disconnect (variant_row_selected);
            lang_variant_widget.clear_variants ();
            lang_variant_widget.variant_listbox.row_selected.connect (variant_row_selected);
            foreach (var country in countries) {
                lang_variant_widget.variant_listbox.add (new CountryRow (country));
            }

            lang_variant_widget.variant_listbox.select_row (lang_variant_widget.variant_listbox.get_row_at_index (0));

            lang_variant_widget.variant_listbox.show_all ();
            Environment.set_variable ("LANGUAGE", lang_entry.get_code (), true);
            Intl.textdomain (Build.GETTEXT_PACKAGE);
            lang_variant_widget.show_variants (_("Languages"), "<b>%s</b>".printf (lang_entry.name));
    }

    private bool timeout () {
        var row = lang_variant_widget.main_listbox.get_row_at_index (select_number);
        if (row == null) {
            select_number = 0;
            row = lang_variant_widget.main_listbox.get_row_at_index (select_number);

            if (row == null) {
                return Source.REMOVE;
            }
        }

        var current_lang = Environment.get_variable ("LANGUAGE");
        Environment.set_variable ("LANGUAGE", ((LangRow) row).lang_entry.get_code (), true);
        Intl.textdomain (Build.GETTEXT_PACKAGE);
        select_label.label = _("Select a Language");

        if (current_lang != null) {
            Environment.set_variable ("LANGUAGE", current_lang, true);
        } else {
            Environment.unset_variable ("LANGUAGE");
        }

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
                    image.icon_name = "selection-checked-symbolic";
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

            image = new Gtk.Image ();
            image.hexpand = true;
            image.halign = Gtk.Align.END;
            image.icon_size = Gtk.IconSize.BUTTON;

            var label = new Gtk.Label (lang_entry.name);
            label.get_style_context ().add_class ("h3");
            label.xalign = 0;

            var grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.margin = 6;
            grid.add (label);
            grid.add (image);

            add (grid);
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
                    image.icon_name = "selection-checked-symbolic";
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
            image = new Gtk.Image ();
            image.hexpand = true;
            image.halign = Gtk.Align.END;
            image.icon_size = Gtk.IconSize.BUTTON;

            var label = new Gtk.Label (country_entry.name);
            label.get_style_context ().add_class ("h3");
            label.xalign = 0;

            var grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.margin = 6;
            grid.add (label);
            grid.add (image);

            add (grid);
        }
    }
}
