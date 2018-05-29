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
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var disk_image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        disk_image.use_fallback = true;

        var name_label = new Gtk.Label (disk_name);
        name_label.halign = Gtk.Align.START;
        name_label.hexpand = true;
        name_label.valign = Gtk.Align.END;

        var size_label = new Gtk.Label ("<small>%s %s</small>".printf (disk_path, GLib.format_size (size)));
        size_label.halign = Gtk.Align.START;
        size_label.use_markup = true;
        size_label.valign = Gtk.Align.START;
        size_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.row_spacing = 6;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.attach (disk_image, 0, 0, 1, 2);
        grid.attach (name_label, 1, 0, 1, 1);
        grid.attach (size_label, 1, 1, 1, 1);
        add (grid);
        notify["active"].connect (() => {
            if (active) {
                unowned Configuration config = Configuration.get_default ();
                var opts = InstallOptions.get_default ();

                if (opts.is_oem_mode ()) {
                    unowned Distinst.InstallOptions options = opts.get_options ();
                    var recovery = options.get_recovery_option ();

                    var lang = Utils.string_from_utf8 (recovery.get_language ());
                    var lang_parts = lang.split ("_", 2);
                    config.lang = lang_parts[0];
                    if (lang_parts.length >= 2) {
                        var country_parts = lang_parts[1].split(".", 2);
                        config.country = country_parts[0];
                    }

                    config.keyboard_layout = Utils.string_from_utf8 (recovery.get_kbd_layout ());

                    var variant = recovery.get_kbd_variant ();
                    if (null != variant) {
                        config.keyboard_variant = Utils.string_from_utf8 (variant);
                    }

                    InstallOptions.get_default ().selected_option = new Distinst.InstallOption () {
                        tag = Distinst.InstallOptionVariant.RECOVERY,
                        option = (void*) recovery,
                        encrypt_pass = null
                    };
                } else {
                    config.disk = disk_path;
                }
            }
        });
    }
}
