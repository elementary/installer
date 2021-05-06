/*-
 * Copyright 2016-2021 elementary, Inc. (https://elementary.io)
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

public class Installer.DiskButton : Gtk.RadioButton {
    public string disk_name { get; construct; }
    public string icon_name { get; construct; }
    public string disk_path { get; construct; }
    public uint64 size { get; construct; }

    public DiskButton (string disk_name, string icon_name, string disk_path, uint64 size) {
        Object (
            disk_name: disk_name,
            icon_name: icon_name,
            disk_path: disk_path,
            size: size
        );
    }

    construct {
        get_style_context ().add_class ("image-button");

        var disk_image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG) {
            use_fallback = true
        };

        var name_label = new Gtk.Label (disk_name) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            halign = Gtk.Align.START,
            valign = Gtk.Align.END
        };
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var size_label = new Gtk.Label ("%s %s".printf (disk_path, GLib.format_size (size))) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START
        };

        var grid = new Gtk.Grid () {
            column_spacing = 3,
            row_spacing = 6,
            margin = 3,
            margin_bottom = 0,
            margin_top = 0,
            hexpand = true
        };
        grid.attach (disk_image, 0, 0, 1, 2);
        grid.attach (name_label, 1, 0);
        grid.attach (size_label, 1, 1);

        add (grid);

        notify["active"].connect (() => {
            if (active) {
                unowned Configuration config = Configuration.get_default ();
                config.disk = disk_path;
            }
        });
    }
}
