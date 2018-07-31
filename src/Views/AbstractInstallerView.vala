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

    public signal void cancel ();

    protected Gtk.Grid content_area;
    protected Gtk.ButtonBox action_area;

    public AbstractInstallerView (bool cancellable = false) {
        Object (
            cancellable: cancellable,
            row_spacing: 24
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

        action_area = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        action_area.margin_end = 10;
        action_area.margin_start = 10;
        action_area.spacing = 6;
        action_area.layout_style = Gtk.ButtonBoxStyle.END;

        if (cancellable) {
            var cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
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
