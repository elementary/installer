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
    construct {
        gkbd_drawing = new Gkbd.KeyboardDrawing ();
        width_request = 600;
        height_request = 230;
        set_layout ("gb\tcolemak");
    }

    public void set_layout (string layout_id) {
        
    }

    public override bool draw (Cairo.Context cr) {
        var pango_context = Gdk.pango_context_get ();
        var layout = new Pango.Layout (pango_context);
        var scale_factor = get_scale_factor ();
        gkbd_drawing.render (cr, layout, 0, 0, get_allocated_width (), get_allocated_height (), scale_factor, scale_factor);
        return true;
    }
}
