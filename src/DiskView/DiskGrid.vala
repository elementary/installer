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

public class Installer.DiskButton : Gtk.ToggleButton {
    public Disk disk { get; construct; }
    public DiskButton (Disk disk) {
        Object (disk: disk);
    }

    construct {
        margin = 12;
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.orientation = Gtk.Orientation.VERTICAL;
        var disk_image = new Gtk.Image.from_icon_name ("drive-harddisk", Gtk.IconSize.DIALOG);
        var name_label = new Gtk.Label (disk.get_label_name ());
        name_label.xalign = 0;
        name_label.hexpand = true;
        var size_label = new Gtk.Label (GLib.format_size (disk.get_size ()));
        size_label.xalign = 0;
        grid.attach (disk_image, 0, 0, 1, 2);
        grid.attach (name_label, 1, 0, 1, 1);
        grid.attach (size_label, 1, 1, 1, 1);
        add (grid);
    }
}
