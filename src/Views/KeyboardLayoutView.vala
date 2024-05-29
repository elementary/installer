/*-
 * Copyright 2017-2021 elementary, Inc. (https://elementary.io)
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

public class KeyboardLayoutView : AbstractInstallerView {
    private VariantWidget input_variant_widget;
    private GLib.Settings keyboard_settings;

    construct {
        keyboard_settings = new GLib.Settings ("org.gnome.desktop.input-sources");

        var image = new Gtk.Image.from_icon_name ("input-keyboard", Gtk.IconSize.DIALOG) {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        var title_label = new Gtk.Label (_("Select Keyboard Layout")) {
            valign = Gtk.Align.START
        };

        input_variant_widget = new VariantWidget ();

        var keyboard_test_entry = new Gtk.Entry () {
            placeholder_text = _("Type to test your layout"),
            secondary_icon_activatable = true,
            secondary_icon_name = "input-keyboard-symbolic",
            secondary_icon_tooltip_text = _("Show keyboard layout")
        };

        var stack_box = new Gtk.Box (VERTICAL, 12);
        stack_box.add (input_variant_widget);
        stack_box.add (keyboard_test_entry);

        title_area.add (image);
        title_area.add (title_label);

        content_area.add (stack_box);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var next_button = new Gtk.Button.with_label (_("Select")) {
            sensitive = false
        };
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_box_end.add (back_button);
        action_box_end.add (next_button);

        input_variant_widget.main_listbox.set_sort_func ((row1, row2) => {
            return ((LayoutRow) row1).layout.description.collate (((LayoutRow) row2).layout.description);
        });

        input_variant_widget.variant_listbox.set_sort_func ((row1, row2) => {
            if (((VariantRow) row1).code == null) {
                return -1;
            }

            if (((VariantRow) row2).code == null) {
                return 1;
            }

            return ((VariantRow) row1).description.collate (((VariantRow) row2).description);
        });

        input_variant_widget.variant_listbox.row_activated.connect (() => {
            next_button.activate ();
        });

        back_button.clicked.connect (() => ((Hdy.Deck) get_parent ()).navigate (BACK));

        next_button.clicked.connect (() => {
            unowned Gtk.ListBoxRow row = input_variant_widget.main_listbox.get_selected_row ();
            if (row != null) {
                var layout = ((LayoutRow) row).layout;
                unowned Configuration configuration = Configuration.get_default ();
                configuration.keyboard_layout = layout.name;

                unowned Gtk.ListBoxRow vrow = input_variant_widget.variant_listbox.get_selected_row ();
                if (vrow != null) {
                    string variant = ((VariantRow) vrow).code;
                    configuration.keyboard_variant = variant;
                } else if (layout.variants.is_empty) {
                    configuration.keyboard_variant = null;
                } else {
                    row.activate ();
                    return;
                }
            } else {
                warning ("next_button enabled when no keyboard selected");
                next_button.sensitive = false;
                return;
            }

            ((Hdy.Deck) get_parent ()).navigate (FORWARD);
        });

        input_variant_widget.main_listbox.row_activated.connect ((row) => {
            var layout = ((LayoutRow) row).layout;
            var variants = layout.variants;
            if (variants.is_empty) {
                return;
            }

            input_variant_widget.clear_variants ();
            input_variant_widget.variant_listbox.add (new VariantRow (null, _("Default")));
            foreach (var variant in variants.entries) {
                input_variant_widget.variant_listbox.add (new VariantRow (variant.key, variant.value));
            }

            input_variant_widget.variant_listbox.select_row (input_variant_widget.variant_listbox.get_row_at_index (0));

            input_variant_widget.show_variants (_("Input Language"), "<b>%s</b>".printf (layout.description));
        });

        input_variant_widget.variant_listbox.row_selected.connect (() => {
            string layout_string = "us";

            unowned Gtk.ListBoxRow row = input_variant_widget.main_listbox.get_selected_row ();
            if (row != null) {
                layout_string = ((LayoutRow) row).layout.name;

                unowned Gtk.ListBoxRow vrow = input_variant_widget.variant_listbox.get_selected_row ();
                if (vrow != null) {
                    string variant = ((VariantRow) vrow).code;
                    if (variant != null && variant != "") {
                        layout_string += "+" + variant;
                    }
                }
            }

            if (!Installer.App.test_mode) {
                Variant[] entries = { new Variant ("(ss)", "xkb", layout_string) };
                var sources = new Variant.array (new VariantType ("(ss)"), entries);
                keyboard_settings.set_value ("sources", sources);
                keyboard_settings.set_value ("current", (uint)0);
            }
        });

        input_variant_widget.main_listbox.row_selected.connect ((row) => {
            next_button.sensitive = true;
        });

        keyboard_test_entry.icon_release.connect (() => {
            string layout_string;
            unowned Gtk.ListBoxRow row = input_variant_widget.main_listbox.get_selected_row ();
            if (row != null) {
                layout_string = ((LayoutRow) row).layout.name;

                unowned Gtk.ListBoxRow vrow = input_variant_widget.variant_listbox.get_selected_row ();
                if (vrow != null) {
                    string variant = ((VariantRow) vrow).code;
                    layout_string += "\t" + variant;
                }
            } else {
                layout_string = "us";
            }

            string command = "gkbd-keyboard-display --layout=%s".printf (layout_string);
            try {
                AppInfo.create_from_commandline (command, null, NONE).launch (null, null);
            } catch (Error e) {
                warning ("Error launching keyboard layout display: %s", e.message);
            }
        });

        foreach (var layout in KeyboardLayoutHelper.get_layouts ()) {
            input_variant_widget.main_listbox.add (new LayoutRow (layout));
        }

        show_all ();

        Idle.add_once (() => {
            string? country = Configuration.get_default ().country;
            if (country != null) {
                string default_layout = country.down ();

                foreach (weak Gtk.Widget child in input_variant_widget.main_listbox.get_children ()) {
                    if (child is LayoutRow) {
                        weak LayoutRow row = (LayoutRow) child;
                        if (row.layout.name == default_layout) {
                            input_variant_widget.main_listbox.select_row (row);
                            row.grab_focus ();
                            break;
                        }
                    }
                }
            }
        });
    }

    private class LayoutRow : Gtk.ListBoxRow {
        public KeyboardLayoutHelper.Layout layout { get; construct; }

        public LayoutRow (KeyboardLayoutHelper.Layout layout) {
            Object (layout: layout);
        }

        construct {
            string layout_description = layout.description;
            if (!layout.variants.is_empty) {
                layout_description = _("%s…").printf (layout_description);
            };

            var label = new Gtk.Label (layout_description) {
                ellipsize = Pango.EllipsizeMode.END,
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6,
                xalign = 0
            };
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            add (label);
            show_all ();
        }
    }

    private class VariantRow : Gtk.ListBoxRow {
        public string? code { get; construct; }
        public string description { get; construct; }

        public VariantRow (string? code, string description) {
            Object (
                code: code,
                description: description
            );
        }

        construct {
            var label = new Gtk.Label (description) {
                ellipsize = Pango.EllipsizeMode.END,
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6,
                xalign = 0
            };
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            add (label);
            show_all ();
        }
    }
}
