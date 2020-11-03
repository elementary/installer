/*-
 * Copyright 2017-2020 elementary, Inc. (https://elementary.io)
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
    public Gtk.SearchEntry search_entry { public get; private set; }
    public Gtk.ListBox main_listbox { public get; private set; }
    public Gtk.ListBox variant_listbox { public get; private set; }

    public signal void going_to_main ();

    private Gtk.Button back_button;
    private Gtk.Grid variant_grid;
    private Gtk.Label variant_title;
    private Hdy.Deck deck;

    construct {
        search_entry = new Gtk.SearchEntry () {
            margin = 3
        };

        main_listbox = new Gtk.ListBox ();

        var main_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        main_scrolled.add (main_listbox);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (search_entry);
        main_grid.add (main_scrolled);

        variant_listbox = new Gtk.ListBox ();
        variant_listbox.activate_on_single_click = false;

        var variant_scrolled = new Gtk.ScrolledWindow (null, null);
        variant_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        variant_scrolled.vexpand = true;
        variant_scrolled.add (variant_listbox);

        back_button = new Gtk.Button ();
        back_button.halign = Gtk.Align.START;
        back_button.margin = 6;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        variant_title = new Gtk.Label (null);
        variant_title.ellipsize = Pango.EllipsizeMode.END;
        variant_title.max_width_chars = 20;
        variant_title.use_markup = true;

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        header_box.hexpand = true;
        header_box.add (back_button);
        header_box.set_center_widget (variant_title);

        variant_grid = new Gtk.Grid ();
        variant_grid.orientation = Gtk.Orientation.VERTICAL;
        variant_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        variant_grid.add (header_box);
        variant_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        variant_grid.add (variant_scrolled);

        deck = new Hdy.Deck () {
            can_swipe_back = true
        };
        deck.add (main_grid);
        deck.add (variant_grid);

        add (deck);

        back_button.clicked.connect (() => {
            going_to_main ();
            deck.navigate (Hdy.NavigationDirection.BACK);
        });
    }

    public void show_variants (string back_button_label, string variant_title_label) {
        back_button.label = back_button_label;
        variant_title.label = variant_title_label;
        deck.visible_child = variant_grid;
    }

    public void clear_variants () {
        variant_listbox.get_children ().foreach ((child) => {
            child.destroy ();
        });
    }
}

public class MainRow : Gtk.ListBoxRow {
    public GLib.Object handler { get; construct; }
    public string label { get; construct; }
    public bool has_variants { get; construct; }
}
