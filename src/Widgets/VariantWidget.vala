/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2017-2023 elementary, Inc. (https://elementary.io)
 */

public class VariantWidget : Gtk.Frame {
    public Gtk.ListBox main_listbox { get; private set; }
    public Gtk.ListBox variant_listbox { get; private set; }

    public signal void going_to_main ();

    private Gtk.Button back_button;
    private Gtk.Box variant_box;
    private Gtk.Label variant_title;
    private Hdy.Deck deck;

    construct {
        main_listbox = new Gtk.ListBox ();

        var main_scrolled = new Gtk.ScrolledWindow (null, null) {
            child = main_listbox,
            hscrollbar_policy = NEVER
        };

        variant_listbox = new Gtk.ListBox ();
        variant_listbox.activate_on_single_click = false;

        var variant_scrolled = new Gtk.ScrolledWindow (null, null) {
            child = variant_listbox,
            hscrollbar_policy = NEVER,
            vexpand = true
        };

        back_button = new Gtk.Button () {
            halign = START,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        variant_title = new Gtk.Label ("") {
            hexpand = true,
            justify = CENTER,
            margin_end = 6,
            margin_start = 6,
            use_markup = true,
            wrap = true
        };

        var header_box = new Gtk.Box (HORIZONTAL, 0) {
            hexpand = true
        };
        header_box.add (back_button);
        header_box.set_center_widget (variant_title);

        variant_box = new Gtk.Box (VERTICAL, 0);
        variant_box.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        variant_box.add (header_box);
        variant_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        variant_box.add (variant_scrolled);

        deck = new Hdy.Deck () {
            can_swipe_back = true
        };
        deck.add (main_scrolled);
        deck.add (variant_box);

        child = deck;
        vexpand = true;

        back_button.clicked.connect (() => {
            going_to_main ();
            deck.navigate (BACK);
        });
    }

    public void show_variants (string back_button_label, string variant_title_label) {
        back_button.label = back_button_label;
        variant_title.label = variant_title_label;
        deck.visible_child = variant_box;
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
