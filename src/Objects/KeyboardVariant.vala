/*-
 * Copyright 2019 elementary, Inc (https://elementary.io)
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

public class Installer.KeyboardVariant : GLib.Object {
    public unowned KeyboardLayout layout { get; construct; }
    public string? name { get; construct; }
    public string? original_name { get; construct; }
    public string display_name {
        get {
            if (name == null)
                return _("Default");

            return dgettext ("xkeyboard-config", original_name);
        }
    }

    public KeyboardVariant (KeyboardLayout layout, string? name, string? original_name) {
        Object (layout: layout, name: name, original_name: original_name);
    }

    public GLib.Variant to_gsd_variant () {
        if (name == null) {
            return layout.to_gsd_variant ();
        } else {
            string xkb_layout_name = "%s(%s)".printf (layout.name, name);
            if (!(xkb_layout_name in KeyboardLayout.NON_LATIN_LAYOUTS)) {
                // Layout can type latin characters, return a single layout
                var primary_layout = new GLib.Variant ("(ss)", "xkb", "%s+%s".printf (layout.name, name));
                return new GLib.Variant.array (new VariantType ("(ss)"), { primary_layout });
            } else {
                // User's layout doesn't use latin characters, also add US layout so they can type a username and password
                var en_us = new GLib.Variant ("(ss)", "xkb", "us");
                var primary_layout = new GLib.Variant ("(ss)", "xkb", "%s+%s".printf (layout.name, name));
                return new GLib.Variant.array (new VariantType ("(ss)"), { en_us, primary_layout });
            }
        }
    }

    public static int compare (KeyboardVariant a, KeyboardVariant b) {
        if (a.name == null) {
            return -1;
        }

        if (b.name == null) {
            return 1;
        }

        return a.display_name.collate (b.display_name);
    }
}
