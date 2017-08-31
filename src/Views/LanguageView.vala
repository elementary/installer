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
    Gtk.Label select_label;
    Gtk.Stack select_stack;
    Gtk.ListBox list_box;
    Gtk.Button next_button;
    int select_number = 0;

    public signal void next_step (string lang);

    public LanguageView (Gtk.Stack navigation_stack) {
        Object (
            row_spacing: 24,
            navigation_stack: navigation_stack
        );

        GLib.Timeout.add_seconds (3, timeout);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("preferences-desktop-locale", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        select_label = new Gtk.Label (null);
        select_label.halign = Gtk.Align.CENTER;
        select_label.wrap = true;

        select_stack = new Gtk.Stack ();
        select_stack.valign = Gtk.Align.START;
        select_stack.get_style_context ().add_class ("h2");
        select_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        select_stack.add (select_label);

        select_stack.notify["transition-running"].connect (() => {
            if (!select_stack.transition_running) {
                select_stack.get_children ().foreach ((child) => {
                    if (child != select_stack.get_visible_child ()) {
                        child.destroy ();
                    }
                });
            }
        });

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.VERTICAL);
        size_group.add_widget (select_stack);
        size_group.add_widget (image);

        list_box = new Gtk.ListBox ();
        list_box.activate_on_single_click = false;
        list_box.expand = true;
        list_box.set_sort_func ((row1, row2) => {
            return ((LangRow) row1).lang.collate (((LangRow) row2).lang);
        });

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (list_box);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;

        foreach (var lang_entry in load_languagelist ().entries) {
            var langrow = new LangRow (lang_entry.key, lang_entry.value);
            list_box.add (langrow);
        }

        var frame = new Gtk.Frame (null);
        frame.add (scrolled);

        next_button = new Gtk.Button.with_label (_("Next"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (next_button);

        list_box.row_selected.connect (row_selected);
        list_box.select_row (list_box.get_row_at_index (0));
        list_box.row_activated.connect ((row) => next_button.clicked ());

        next_button.clicked.connect (() => {
            // We need to disconnect the signal otherwise it's called several time when destroying the window…
            list_box.row_selected.disconnect (row_selected);
            unowned Gtk.ListBoxRow row = list_box.get_selected_row ();
            unowned string lang = ((LangRow) row).lang;
            Environment.set_variable ("LANGUAGE", lang, true);
            next_step (lang);
        });

        content_area.column_homogeneous = true;
        content_area.margin_end = 10;
        content_area.margin_start = 10;
        content_area.attach (image, 0, 0, 1, 1);
        content_area.attach (select_stack, 0, 1, 1, 1);
        content_area.attach (frame, 1, 0, 1, 2);

        timeout ();
    }

    private void row_selected (Gtk.ListBoxRow? row) {
        var current_lang = Environment.get_variable ("LANGUAGE");
        Environment.set_variable ("LANGUAGE", ((LangRow) row).lang, true);
        Intl.textdomain ("pantheon-installer");

        next_button.label = _("Next");

        foreach (Gtk.Widget child in list_box.get_children ()) {
            if (child is LangRow) {
                var lang_row = (LangRow) child;

                if (lang_row.lang == ((LangRow) row).lang) {
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
    }

    private bool timeout () {
        var row = list_box.get_row_at_index (select_number);
        if (row == null) {
            select_number = 0;
            row = list_box.get_row_at_index (select_number);
        }

        var current_lang = Environment.get_variable ("LANGUAGE");
        Environment.set_variable ("LANGUAGE", ((LangRow) row).lang, true);
        Intl.textdomain ("pantheon-installer");
        select_label = new Gtk.Label (_("Select a Language"));
        select_label.show_all ();
        select_stack.add (select_label);
        select_stack.set_visible_child (select_label);

        if (current_lang != null) {
            Environment.set_variable ("LANGUAGE", current_lang, true);
        } else {
            Environment.unset_variable ("LANGUAGE");
        }

        select_number++;
        return GLib.Source.CONTINUE;
    }

    Gee.HashMap<string, string> load_languagelist () {
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

    private string get_iso_639_3_name (string lang_code, Xml.Node* root) {
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

    private string get_country_name (string country_code) {
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
                            return iter->get_prop ("name");
                        }
                    }
                }
            }
        }

        return null;
    }

    public class LangRow : Gtk.ListBoxRow {
        private Gtk.Image image;
        public string lang;

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

        public LangRow (string lang, string translated_name) {
            this.lang = lang;

            image = new Gtk.Image ();
            image.hexpand = true;
            image.halign = Gtk.Align.END;
            image.icon_size = Gtk.IconSize.BUTTON;

            var label = new Gtk.Label (translated_name);
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
