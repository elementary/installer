// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017–2018 elementary LLC. (https://elementary.io)
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

public abstract class AbstractInstallerView : Gtk.Grid {
    public bool cancellable { get; construct; }
    public unowned Gtk.Widget? previous_view { get; set; }
    public Gtk.Label? test_label = null;
    public Gtk.Button cancel_button;

    public string artwork { get; construct; }
    public string title { get; construct; }
    public Gtk.Label? title_label;
    public Gtk.Widget? title_widget { get; construct; }

    public signal void cancel ();

    protected Gtk.Grid content_area;
    protected Gtk.ButtonBox action_area;

    public AbstractInstallerView (
        bool cancellable = false,
        string? title = null,
        string? artwork = null,
        Gtk.Widget? title_widget = null
    ) {
        Object (
            cancellable: cancellable,
            row_spacing: 24,
            title: title,
            title_widget: title_widget,
            artwork: artwork
        );
    }

    construct {
        content_area = new Gtk.Grid ();
        content_area.column_spacing = 12;
        content_area.row_spacing = 12;
        content_area.margin = 12;
        content_area.expand = true;
        content_area.orientation = Gtk.Orientation.VERTICAL;
        content_area.column_homogeneous = true;
        content_area.valign = Gtk.Align.FILL;
        content_area.halign = Gtk.Align.FILL;

        if (artwork != null && (title != null || title_widget != null)) {
            Gtk.Widget title_w;
            if (title_widget != null) {
                title_w = title_widget;
            } else {
                title_label = new Gtk.Label (title);
                title_label.max_width_chars = 60;
                title_label.get_style_context ().add_class ("h2");
                title_label.margin_bottom = 42;
                title_w = (Gtk.Widget) title_label;
            }

            title_w.valign = Gtk.Align.START;
            title_w.halign = Gtk.Align.CENTER;

            var artwork = new Gtk.Grid ();
            artwork.get_style_context ().add_class (this.artwork);
            artwork.get_style_context ().add_class ("artwork");
            artwork.vexpand = true;

            content_area.attach (artwork, 0, 0);
            content_area.attach (title_w, 0, 1);
        }

        action_area = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        action_area.margin_end = 10;
        action_area.margin_start = 10;
        action_area.spacing = 6;
        action_area.layout_style = Gtk.ButtonBoxStyle.END;
        action_area.homogeneous = true;

        if (cancellable) {
            cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
            cancel_button.clicked.connect (() => {
                cancel ();
            });

            action_area.add (cancel_button);
        }

        if (Installer.App.test_mode) {
            test_label = new Gtk.Label (_("Test Mode"));
            test_label.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

            action_area.add (test_label);
            action_area.set_child_non_homogeneous (test_label, true);
            action_area.set_child_secondary (test_label, true);
        }

        orientation = Gtk.Orientation.VERTICAL;
        add (content_area);
        add (action_area);

        if (cancellable) {
            key_press_event.connect ((event) => {
                switch (event.keyval) {
                    case Gdk.Key.Left:
                        if (event.state != Gdk.ModifierType.MOD1_MASK) {
                            break;
                        }
                    case Gdk.Key.Escape:
                        cancel ();
                        return true;
                }

                return false;
            });
        }
    }
}
