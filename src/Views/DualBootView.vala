/*
 * Copyright (c) 2018 elementary, Inc. (https://elementary.io)
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

public class DualBootView : AbstractInstallerView {
    construct {
        var image = new Gtk.Image.from_icon_name ("drive-harddisk", Gtk.IconSize.DIALOG);
        image.vexpand = true;
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Set Aside Space"));
        title_label.valign = Gtk.Align.START;
        title_label.get_style_context ().add_class ("h2");

        var secondary_label = new Gtk.Label (
            _("Each operating system needs space on your device. Drag the bar below to set how much space each operating system gets.")
        );
        secondary_label.max_width_chars = 60;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);
        scale.add_mark (50, Gtk.PositionType.BOTTOM, "");
        scale.draw_value = false;
        scale.inverted = true;
        scale.set_value (50);

        var our_os_label = new Gtk.Label (_("elementary OS"));
        our_os_label.halign = Gtk.Align.END;
        our_os_label.hexpand = true;
        our_os_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var our_os_size = new Gtk.Label (_("20 GB"));
        our_os_size.halign = Gtk.Align.END;
        our_os_size.hexpand = true;

        var other_os_label = new Gtk.Label (_("Other OS"));
        other_os_label.halign = Gtk.Align.START;
        other_os_label.hexpand = true;
        other_os_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var other_os_size = new Gtk.Label (_("""32 GB <span alpha="67%">(17 GB Free)</span>"""));
        other_os_size.halign = Gtk.Align.START;
        other_os_size.hexpand = true;
        other_os_size.use_markup = true;

        var scale_grid = new Gtk.Grid ();
        scale_grid.halign = Gtk.Align.FILL;

        scale_grid.attach (scale,          0, 0, 2);
        scale_grid.attach (other_os_label, 0, 1);
        scale_grid.attach (our_os_label,   1, 1);
        scale_grid.attach (other_os_size,  0, 2);
        scale_grid.attach (our_os_size,    1, 2);

        var grid = new Gtk.Grid ();
        grid.row_spacing = 12;
        grid.valign = Gtk.Align.CENTER;

        grid.attach (secondary_label, 0, 0);
        grid.attach (scale_grid,      0, 1);

        content_area.column_homogeneous = true;
        content_area.halign = Gtk.Align.CENTER;
        content_area.margin = 48;
        content_area.margin_start = content_area.margin_end = 12;
        content_area.valign = Gtk.Align.CENTER;

        content_area.attach (image,       0, 0);
        content_area.attach (title_label, 0, 1);
        content_area.attach (grid,        1, 0, 1, 2);

        var next_button = new Gtk.Button.with_label (_("Erase and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        next_button.sensitive = false;
        // next_button.clicked.connect (() => next_step ());

        action_area.add (next_button);

        show_all ();
    }
}

