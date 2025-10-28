/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2017-2024 elementary, Inc. (https://elementary.io)
 */

public abstract class AbstractInstallerView : Adw.NavigationPage {
    public bool cancellable { get; construct; }

    public signal void next_step ();

    protected Gtk.Box title_area;
    protected Gtk.Box content_area;
    protected Gtk.Box action_box_start;
    protected Gtk.Box action_box_end;

    protected AbstractInstallerView (bool cancellable = false) {
        Object (cancellable: cancellable);
    }

    construct {
        title_area = new Gtk.Box (VERTICAL, 12) {
            valign = CENTER
        };
        title_area.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        content_area = new Gtk.Box (VERTICAL, 24);

        var content_clamp = new Adw.Clamp () {
            child = content_area
        };

        var box = new Gtk.Box (HORIZONTAL, 12) {
            homogeneous = true,
            hexpand = true,
            vexpand = true,
        };
        box.append (title_area);
        box.append (content_clamp);

        action_box_end = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            hexpand = true,
            homogeneous = true
        };

        action_box_start = new Gtk.Box (HORIZONTAL, 6) {
            homogeneous = true
        };

        var action_area = new Gtk.Box (HORIZONTAL, 12);
        action_area.append (action_box_start);
        action_area.add_css_class ("button-box");

        if (Installer.App.test_mode) {
            var test_label = new Gtk.Label (_("Test Mode"));
            test_label.add_css_class (Granite.CssClass.ERROR);

            action_area.append (test_label);
        }

        action_area.append (action_box_end);

        if (cancellable) {
            var cancel_button = new Gtk.Button.with_label (_("Cancel Installation")) {
                action_name = "win.back"
            };

            action_box_end.append (cancel_button);
        }

        var main_box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        main_box.append (box);
        main_box.append (action_area);

        child = main_box;
    }
}
