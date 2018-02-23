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

public class KeyboardLayoutView : AbstractInstallerView {
    public signal void next_step ();

    private VariantWidget input_variant_widget;

    construct {
        var image = new Gtk.Image.from_icon_name ("input-keyboard", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Keyboard Layout"));
        title_label.get_style_context ().add_class ("h2");
        title_label.valign = Gtk.Align.START;

        input_variant_widget = new VariantWidget ();

        var keyboard_test_entry = new Gtk.Entry ();
        keyboard_test_entry.hexpand = true;
        keyboard_test_entry.placeholder_text = _("Type to test your layout");
        keyboard_test_entry.secondary_icon_activatable = true;
        keyboard_test_entry.secondary_icon_name = "input-keyboard-symbolic";
        keyboard_test_entry.secondary_icon_tooltip_text = _("Show keyboard layout");

        var stack_grid = new Gtk.Grid ();
        stack_grid.orientation = Gtk.Orientation.VERTICAL;
        stack_grid.row_spacing = 12;
        stack_grid.add (input_variant_widget);
        stack_grid.add (keyboard_test_entry);

        content_area.column_homogeneous = true;
        content_area.margin_end = 12;
        content_area.margin_start = 12;
        content_area.attach (image, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (stack_grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var next_button = new Gtk.Button.with_label (_("Select"));
        next_button.sensitive = false;
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (back_button);
        action_area.add (next_button);

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

        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        next_button.clicked.connect (() => next_step ());

        input_variant_widget.going_to_main.connect (() => {
            next_button.sensitive = false;
        });

        input_variant_widget.main_listbox.row_activated.connect ((row) => {
            var layout = ((LayoutRow) row).layout;

            unowned Configuration config = Configuration.get_default ();
            config.keyboard_layout = layout.name;
            config.keyboard_variant = null;

            var variants = layout.variants;
            if (variants.is_empty) {
                next_button.sensitive = true;
                return;
            }

            input_variant_widget.clear_variants ();
            input_variant_widget.variant_listbox.add (new VariantRow (null, _("Default")));
            foreach (var variant in variants.entries) {
                input_variant_widget.variant_listbox.add (new VariantRow (variant.key, variant.value));
            }

            input_variant_widget.variant_listbox.select_row(input_variant_widget.variant_listbox.get_row_at_index(0));

            input_variant_widget.show_variants (_("Input Language"), "<b>%s</b>".printf (layout.description));
        });

        input_variant_widget.variant_listbox.row_selected.connect ((row) => {
            unowned Configuration config = Configuration.get_default ();
            if (row != null) {
                config.keyboard_variant = ((VariantRow) row).code;
            } else {
                config.keyboard_variant = null;
            }

            next_button.sensitive = true;
        });

        keyboard_test_entry.icon_release.connect (() => {
            var popover = new Gtk.Popover (keyboard_test_entry);
            var layout = new LayoutWidget ();

            var layout_string = "us";
            unowned Configuration config = Configuration.get_default ();
            if (config.keyboard_layout != null) {
                layout_string = config.keyboard_layout;
                if (config.keyboard_variant != null) {
                    layout_string += "\t" + config.keyboard_variant;
                }
            }

            layout.set_layout (layout_string);
            popover.add (layout);
            popover.show_all ();
        });

        foreach (var layout in KeyboardLayoutHelper.get_layouts ()) {
            input_variant_widget.main_listbox.add (new LayoutRow (layout));
        }

        show_all ();
    }

    private class LayoutRow : Gtk.ListBoxRow {
        public KeyboardLayoutHelper.Layout layout;
        public LayoutRow (KeyboardLayoutHelper.Layout layout) {
            this.layout = layout;

            string layout_description = layout.description;
            if (!layout.variants.is_empty) {
                layout_description = _("%s…").printf (layout_description);
            };

            var label = new Gtk.Label (layout_description);
            label.margin = 6;
            label.xalign = 0;
            label.get_style_context ().add_class ("h3");
            add (label);
            show_all ();
        }
    }

    private class VariantRow : Gtk.ListBoxRow {
        public string? code;
        public string description;
        public VariantRow (string? code, string description) {
            this.code = code;
            this.description = description;
            var label = new Gtk.Label (description);
            label.margin = 6;
            label.xalign = 0;
            label.get_style_context ().add_class ("h3");
            add (label);
            show_all ();
        }
    }
}
