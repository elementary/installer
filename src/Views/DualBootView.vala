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
    // NOTE: Temporary for mockup
    public const int TOTAL_DISK = 250;
    public const int DISK_USED = 15;
    public const int MIN_SIZE = 10;

    private Gtk.SpinButton our_os_size_spin { get; set; }
    private Gtk.SpinButton other_os_size_spin { get; set; }
    private Gtk.Label our_os_free_label { get; set; }
    private Gtk.Label other_os_free_label { get; set; }


    construct {
        var image = new Gtk.Image.from_icon_name ("drive-harddisk", Gtk.IconSize.DIALOG);
        image.vexpand = true;
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Set Aside Space"));
        title_label.valign = Gtk.Align.START;
        title_label.get_style_context ().add_class ("h2");

        var secondary_label = new Gtk.Label (
            _("Each operating system needs space on your device. Drag the handle below to set how much space each operating system gets.")
        );
        secondary_label.max_width_chars = 60;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, TOTAL_DISK, 1);
        scale.add_mark (TOTAL_DISK / 2, Gtk.PositionType.BOTTOM, "");
        scale.draw_value = false;
        scale.fill_level = TOTAL_DISK - DISK_USED;
        scale.inverted = true;
        scale.set_value (TOTAL_DISK / 2);
        scale.show_fill_level = true;
        scale.get_style_context ().add_class (Granite.STYLE_CLASS_ACCENT);

        var our_os_label = new Gtk.Label (Utils.get_pretty_name ());
        our_os_label.halign = Gtk.Align.END;
        our_os_label.hexpand = true;

        var our_os_label_context = our_os_label.get_style_context ();
        our_os_label_context.add_class (Granite.STYLE_CLASS_H3_LABEL);
        our_os_label_context.add_class (Granite.STYLE_CLASS_ACCENT);

        our_os_size_spin = new Gtk.SpinButton.with_range (0, TOTAL_DISK, 1);
        our_os_size_spin.halign = Gtk.Align.END;

        var our_os_unit_label = new Gtk.Label ("GB");
        our_os_unit_label.width_request = 0;
        our_os_unit_label.halign = Gtk.Align.END;

        our_os_free_label = new Gtk.Label ("");
        our_os_free_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        our_os_free_label.halign = Gtk.Align.END;

        var our_spin_grid = new Gtk.Grid ();
        our_spin_grid.column_spacing = 6;
        our_spin_grid.halign = Gtk.Align.END;

        our_spin_grid.add (our_os_size_spin);
        our_spin_grid.add (our_os_unit_label);

        var other_os_label = new Gtk.Label (_("Other OS"));
        other_os_label.halign = Gtk.Align.START;
        other_os_label.hexpand = true;
        other_os_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        other_os_size_spin = new Gtk.SpinButton.with_range (0, TOTAL_DISK, 1);
        other_os_size_spin.halign = Gtk.Align.START;

        var other_os_unit_label = new Gtk.Label ("GB");
        other_os_unit_label.halign = Gtk.Align.START;
        other_os_unit_label.hexpand = true;

        other_os_free_label = new Gtk.Label ("");
        other_os_free_label.halign = Gtk.Align.START;
        other_os_free_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var other_spin_grid = new Gtk.Grid ();
        other_spin_grid.column_spacing = 6;
        other_spin_grid.halign = Gtk.Align.START;

        other_spin_grid.add (other_os_size_spin);
        other_spin_grid.add (other_os_unit_label);

        var scale_grid = new Gtk.Grid ();
        scale_grid.column_spacing = 6;
        scale_grid.halign = Gtk.Align.FILL;
        scale_grid.row_spacing = 6;

        scale_grid.attach (scale,               0, 0, 2);
        scale_grid.attach (other_os_label,      0, 1);
        scale_grid.attach (our_os_label,        1, 1);
        scale_grid.attach (other_spin_grid,     0, 2);
        scale_grid.attach (our_spin_grid,       1, 2);
        scale_grid.attach (other_os_free_label, 0, 3);
        scale_grid.attach (our_os_free_label,   1, 3);

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

        var next_button = new Gtk.Button.with_label (_("Resize and Install"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        // next_button.clicked.connect (() => next_step ());

        action_area.add (next_button);
        update_sizes ((int)scale.get_value ());
        show_all ();

        scale.value_changed.connect (() => {
            constrain_scale (scale);
            update_sizes ((int)scale.get_value ());
        });

        our_os_size_spin.change_value.connect (() => {
            update_sizes ((int)our_os_size_spin.value);
        });

        other_os_size_spin.change_value.connect (() => {
            update_sizes ((int)other_os_size_spin.value);
        });
    }

    private void constrain_scale (Gtk.Scale scale) {
        if (scale.get_value () < MIN_SIZE) {
            scale.set_value (MIN_SIZE);
        }
    }

    private void update_sizes (int our_os_size) {
        int other_os_size = TOTAL_DISK - our_os_size;

        our_os_size_spin.value = our_os_size;

        our_os_free_label.label = _("%i GB Free".printf (
            our_os_size - MIN_SIZE
        ));

        other_os_size_spin.value = other_os_size;

        other_os_free_label.label = _("%i GB Free".printf (
            other_os_size - DISK_USED
        ));
    }
}

