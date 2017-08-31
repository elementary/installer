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

    static Gkbd.KeyboardDrawingGroupLevel top_left = Gkbd.KeyboardDrawingGroupLevel ();
    static Gkbd.KeyboardDrawingGroupLevel top_right = Gkbd.KeyboardDrawingGroupLevel ();
    static Gkbd.KeyboardDrawingGroupLevel bottom_left = Gkbd.KeyboardDrawingGroupLevel ();
    static Gkbd.KeyboardDrawingGroupLevel bottom_right = Gkbd.KeyboardDrawingGroupLevel ();
    static (unowned Gkbd.KeyboardDrawingGroupLevel)[] group = {top_left, top_right, bottom_left, bottom_right};

    static construct {
        top_left.group = 0;
        top_left.level = 1;

        top_right.group = 0;
        top_right.level = 3;

        bottom_left.group = 0;
        bottom_left.level = 0;

        bottom_right.group = 0;
        bottom_right.level = 2;
    }

    construct {
        gkbd_drawing = new Gkbd.KeyboardDrawing ();
        gkbd_drawing.parent = this;
        width_request = 600;
        height_request = 230;
        gkbd_drawing.set_groups_levels (group);
        set_layout ("gb\tcolemak");
        gkbd_drawing.show_all ();
    }

    public void set_layout (string layout_id) {
        gkbd_drawing.set_layout (layout_id);
    }

    public override bool draw (Cairo.Context cr) {
        var scale_factor = get_scale_factor ();
        gkbd_drawing.render (cr,
        Pango.cairo_create_layout (cr), 0, 0,
            get_allocated_width (),
            get_allocated_height (),
            scale_factor,
            scale_factor
        );
        return true;
    }
}
