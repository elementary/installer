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

public class LayoutWidget : Gtk.Grid {
    private Gkbd.KeyboardDrawing gkbd_drawing;

    static Gkbd.KeyboardDrawingGroupLevel top_left = { 0, 1 };
    static Gkbd.KeyboardDrawingGroupLevel top_right = { 0, 3 };
    static Gkbd.KeyboardDrawingGroupLevel bottom_left = { 0, 0 };
    static Gkbd.KeyboardDrawingGroupLevel bottom_right = { 0, 2 };
    Gkbd.KeyboardDrawingGroupLevel*[] group = { &top_left, &top_right, &bottom_left, &bottom_right };

    construct {
        gkbd_drawing = new Gkbd.KeyboardDrawing ();
        gkbd_drawing.parent = this;
        width_request = 600;
        height_request = 230;
        gkbd_drawing.set_groups_levels (((unowned Gkbd.KeyboardDrawingGroupLevel)[])group);
        set_layout ("gb\tcolemak");
        gkbd_drawing.show_all ();
    }

    public void set_layout (string layout_id) {
        gkbd_drawing.set_layout (layout_id);
    }

    public override bool draw (Cairo.Context cr) {
        gkbd_drawing.render (cr,
        Pango.cairo_create_layout (cr), 0, 0,
            get_allocated_width (),
            get_allocated_height (),
            50,
            50
        );
        return true;
    }
}
