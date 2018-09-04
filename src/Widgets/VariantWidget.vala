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

public class VariantWidget : Gtk.Frame {
    public Gtk.ListBox main_listbox { public get; private set; }
    public Gtk.ListBox variant_listbox { public get; private set; }

    public signal void going_to_main ();

    private Gtk.Button back_button;
    private Gtk.Label variant_title;
    private Gtk.Stack stack;

    construct {
        main_listbox = new Gtk.ListBox ();
        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.add (main_listbox);

        variant_listbox = new Gtk.ListBox ();
        variant_listbox.activate_on_single_click = false;

        var variant_scrolled = new Gtk.ScrolledWindow (null, null);
        variant_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        variant_scrolled.vexpand = true;
        variant_scrolled.add (variant_listbox);

        back_button = new Gtk.Button ();
        back_button.halign = Gtk.Align.START;
        back_button.margin = 6;
        back_button.get_style_context ().add_class ("back-button");

        variant_title = new Gtk.Label (null);
        variant_title.ellipsize = Pango.EllipsizeMode.END;
        variant_title.max_width_chars = 20;
        variant_title.use_markup = true;

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        header_box.hexpand = true;
        header_box.add (back_button);
        header_box.set_center_widget (variant_title);

        var variant_grid = new Gtk.Grid ();
        variant_grid.orientation = Gtk.Orientation.VERTICAL;
        variant_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        variant_grid.add (header_box);
        variant_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        variant_grid.add (variant_scrolled);

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add_named (main_scrolled, "main");
        stack.add_named (variant_grid, "variant");
        add (stack);

        back_button.clicked.connect (() => {
            going_to_main ();
            stack.visible_child_name = "main";
            unset_variant ();
        });
    }

    public void show_variants (string back_button_label, string variant_title_label) {
        back_button.label = back_button_label;
        variant_title.label = variant_title_label;
        stack.visible_child_name = "variant";
    }

    public void clear_variants () {
        variant_listbox.get_children ().foreach ((child) => {
            child.destroy ();
        });
    }

    private void unset_variant () {
        weak Gtk.ListBoxRow row = variant_listbox.get_selected_row ();
        if (row != null) variant_listbox.unselect_row (row);
    }
}

public class MainRow : Gtk.ListBoxRow {
    public GLib.Object handler { get; construct; }
    public string label { get; construct; }
    public bool has_variants { get; construct; }
}
