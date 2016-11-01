// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Installer.DiskGrid : Gtk.Grid {
    public Disk disk;
    public Gee.LinkedList<ToggleOSButton> buttons;
    public DiskGrid (Disk disk) {
        this.disk = disk;
        show_all ();
    }

    construct {
        margin = 12;
        column_spacing = 6;
        orientation = Gtk.Orientation.HORIZONTAL;
        halign = Gtk.Align.CENTER;
        buttons = new Gee.LinkedList<ToggleOSButton> ();
    }

    public void add_button (string name, string? version, GLib.Icon icon, Partition partition) {
        var button = new ToggleOSButton (name, version, icon, partition);
        button.show_all ();
        buttons.add (button);
        add (button);
    }

    public class ToggleOSButton : Gtk.ToggleButton {
        unowned Partition partition;
        Gtk.Label description;
        Gtk.Label size;
        Gtk.Image icon_image;
        Gtk.Grid grid;
        public ToggleOSButton (string name, string? version, GLib.Icon icon, Partition partition) {
            this.partition = partition;
            if (version != null) {
                description.label = "%s %s".printf (name, version);
            } else {
                description.label = name;
            }

            size.label = "(%s)".printf (GLib.format_size (partition.get_size ()));
            icon_image.gicon = icon;
            show_all ();
        }
        
        construct {
            get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.column_spacing = 6;
            grid.row_spacing = 12;
            description = new Gtk.Label (null);
            description.xalign = 1;
            size = new Gtk.Label (null);
            size.xalign = 0;
            size.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            icon_image = new Gtk.Image ();
            icon_image.halign = Gtk.Align.CENTER;
            icon_image.icon_size = Gtk.IconSize.DIALOG;
            grid.attach (icon_image, 0, 0, 2, 1);
            grid.attach (description, 0, 1, 1, 1);
            grid.attach (size, 1, 1, 1, 1);
            add (grid);
        }
    }
}
