// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
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

namespace KeyboardLayoutHelper {
    public struct Layout {
        public string name;
        public string description;
        public Gee.HashMap<string, string> variants;
    }

    public static Gee.LinkedList<Layout?> get_layouts () {
        var layouts = new Gee.LinkedList<Layout?> ();

        var distinst_layouts = new Distinst.KeyboardLayouts ();
        if (distinst_layouts == null) {
            return layouts;
        }

        foreach (unowned Distinst.KeyboardLayout layout in distinst_layouts.get_layouts ()) {
            var variant_map = new Gee.HashMap<string, string> ();
            var variants = layout.get_variants ();
            if (variants != null) {
                foreach (unowned Distinst.KeyboardVariant variant in variants) {
                    var name = Utils.string_from_utf8 (variant.get_name ());
                    var desc = Utils.string_from_utf8 (variant.get_description ());
                    variant_map[name] = dgettext ("xkeyboard-config", desc);
                }
            }
            layouts.add (Layout () {
                name = Utils.string_from_utf8 (layout.get_name ()),
                description = dgettext ("xkeyboard-config", Utils.string_from_utf8 (layout.get_description ())),
                variants = variant_map
            });
        }

        return layouts;
    }
}
