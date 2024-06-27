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
                GLib.Variant? layout_variant = null;

                unowned Gtk.ListBoxRow vrow = input_variant_widget.variant_listbox.get_selected_row ();
                if (vrow != null) {
                    unowned var variant = ((VariantRow) vrow).variant;
                    configuration.keyboard_variant = variant.name;
                } else if (!layout.has_variants ()) {
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
            unowned var layout = ((LayoutRow) row).layout;
            if (!layout.has_variants ()) {
                return;
            }

            input_variant_widget.variant_listbox.bind_model (layout.get_variants (), (variant) => {
                return new VariantRow (variant as Installer.KeyboardVariant);
            });

            input_variant_widget.variant_listbox.select_row (input_variant_widget.variant_listbox.get_row_at_index (0));

            input_variant_widget.show_variants (_("Input Language"), "<b>%s</b>".printf (layout.display_name));
        });

        input_variant_widget.variant_listbox.row_selected.connect (() => {
            unowned var row = input_variant_widget.main_listbox.get_selected_row ();
            if (row != null) {
                var layout = ((LayoutRow) row).layout;
                unowned var configuration = Configuration.get_default ();
                configuration.keyboard_layout = layout.name;
                GLib.Variant? layout_variant = null;

                unowned var vrow = input_variant_widget.variant_listbox.get_selected_row ();
                if (vrow != null) {
                    unowned var variant = ((VariantRow) vrow).variant;
                    configuration.keyboard_variant = variant.name;
                    if (variant != null) {
                        layout_variant = variant.to_gsd_variant ();
                    }
                } else if (!layout.has_variants ()) {
                    configuration.keyboard_variant = null;
                }

                if (layout_variant == null) {
                    layout_variant = layout.to_gsd_variant ();
                }

                if (!Installer.App.test_mode) {
                    keyboard_settings.set_value ("sources", layout_variant);
                    keyboard_settings.set_uint ("current", 0);
                }
            }
        });

        input_variant_widget.main_listbox.row_selected.connect ((row) => {
            next_button.sensitive = true;
        });

        keyboard_test_entry.icon_release.connect (() => {
            var layout_string = "us";
            unowned var config = Configuration.get_default ();
            if (config.keyboard_layout != null) {
                layout_string = config.keyboard_layout;
                if (config.keyboard_variant != null) {
                    layout_string += "\t" + config.keyboard_variant;
                }
            }

            string command = "gkbd-keyboard-display --layout=%s".printf (layout_string);
            try {
                AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE).launch (null, null);
            } catch (Error e) {
                warning ("Error launching keyboard layout display: %s", e.message);
            }
        });

        input_variant_widget.main_listbox.bind_model (Installer.KeyboardLayout.get_all (), (layout) => {
            return new LayoutRow (layout as Installer.KeyboardLayout);
        });

        show_all ();

        Idle.add_once (() => {
            unowned string? country = Configuration.get_default ().country;
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
        public unowned Installer.KeyboardLayout layout { get; construct; }

        public LayoutRow (Installer.KeyboardLayout layout) {
            Object (layout: layout);
        }

        construct {
            string layout_description = layout.display_name;
            if (layout.has_variants ()) {
                layout_description = _("%s…").printf (layout_description);
            }

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
        public unowned Installer.KeyboardVariant variant { get; construct; }

        public VariantRow (Installer.KeyboardVariant variant) {
            Object (variant: variant);
        }

        construct {
            var label = new Gtk.Label (variant.display_name) {
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
