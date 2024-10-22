/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2017-2023 elementary, Inc. (https://elementary.io)
 */

public class VariantWidget : Gtk.Frame {
    public string main_title { get; construct; }

    public Gtk.ListBox main_listbox { get; private set; }
    public Gtk.ListBox variant_listbox { get; private set; }

    public signal void going_to_main ();

    private Gtk.Box variant_box;
    private Adw.NavigationView navigation_view;
    private Adw.NavigationPage variant_page;

    public VariantWidget (string main_title) {
        Object (main_title: main_title);
    }

    construct {
        main_listbox = new Gtk.ListBox ();

        var main_scrolled = new Gtk.ScrolledWindow () {
            child = main_listbox,
            hscrollbar_policy = NEVER
        };

        var main_page = new Adw.NavigationPage (main_scrolled, main_title);

        variant_listbox = new Gtk.ListBox ();
        variant_listbox.activate_on_single_click = false;

        var variant_scrolled = new Gtk.ScrolledWindow () {
            child = variant_listbox,
            hscrollbar_policy = NEVER,
            vexpand = true
        };

        var back_button = new Gtk.Button.with_label (main_page.title) {
            halign = START,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var variant_title = new Gtk.Label ("") {
            hexpand = true,
            justify = CENTER,
            margin_end = 6,
            margin_start = 6,
            mnemonic_widget = variant_listbox,
            wrap = true
        };
        variant_title.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        var header_box = new Gtk.CenterBox () {
            start_widget = back_button,
            center_widget = variant_title,
            hexpand = true
        };

        variant_box = new Gtk.Box (VERTICAL, 0);
        variant_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        variant_box.append (header_box);
        variant_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        variant_box.append (variant_scrolled);

        variant_page = new Adw.NavigationPage (variant_box, "");

        navigation_view = new Adw.NavigationView ();
        navigation_view.add (main_page);

        child = navigation_view;
        vexpand = true;

        back_button.clicked.connect (() => {
            going_to_main ();
            navigation_view.pop ();
        });

        variant_page.bind_property ("title", variant_title, "label");
    }

    public void show_variants (string variant_title_label) {
        variant_page.title = variant_title_label;
        navigation_view.push (variant_page);

        variant_listbox.get_selected_row ().grab_focus ();
    }

    public void clear_variants () {
        variant_listbox.remove_all ();
    }
}

public class MainRow : Gtk.ListBoxRow {
    public GLib.Object handler { get; construct; }
    public string label { get; construct; }
    public bool has_variants { get; construct; }
}
