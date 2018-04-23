// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017–2018 elementary LLC. (https://elementary.io)
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

public class TryInstallView : AbstractInstallerView {
    public signal void next_step ();

    construct {
        var image = new Gtk.Image.from_icon_name ("system-os-installer", Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.END;

        var title_label = new Gtk.Label (_("Install or Try Demo Mode"));
        title_label.max_width_chars = 60;
        title_label.valign = Gtk.Align.START;
        title_label.get_style_context ().add_class ("h2");

        var choice_image = new Gtk.Image.from_icon_name ("computer-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        choice_image.halign = Gtk.Align.END;
        choice_image.valign = Gtk.Align.START;

        var choice_label = new Gtk.Label (_("You can install %s on this device now, or try Demo Mode without installing.").printf (Utils.get_pretty_name ()));
        choice_label.halign = Gtk.Align.START;
        choice_label.max_width_chars = 52;
        choice_label.valign = Gtk.Align.START;
        choice_label.wrap = true;
        choice_label.xalign = 0;

        var implications_image = new Gtk.Image.from_icon_name ("document-revert-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        implications_image.halign = Gtk.Align.END;
        implications_image.valign = Gtk.Align.START;

        var implications_label = new Gtk.Label (_("In Demo Mode, changes you make will not be saved and data from your previous operating system will be unchanged. Performance and features may not reflect the installed experience."));
        implications_label.halign = Gtk.Align.START;
        implications_label.max_width_chars = 52;
        implications_label.valign = Gtk.Align.START;
        implications_label.wrap = true;
        implications_label.xalign = 0;

        var return_image = new Gtk.Image.from_icon_name ("go-home-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        return_image.halign = Gtk.Align.END;
        return_image.valign = Gtk.Align.START;

        var return_label = new Gtk.Label (_("You can always return to the installer from Demo Mode by selecting the Install icon."));
        return_label.halign = Gtk.Align.START;
        return_label.max_width_chars = 52;
        return_label.valign = Gtk.Align.START;
        return_label.wrap = true;
        return_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 32;

        grid.attach (choice_image, 0, 1, 1, 1);
        grid.attach (choice_label, 1, 1, 1, 1);
        grid.attach (implications_image, 0, 2, 1, 1);
        grid.attach (implications_label, 1, 2, 1, 1);
        grid.attach (return_image, 0, 3, 1, 1);
        grid.attach (return_label, 1, 3, 1, 1);

        content_area.column_homogeneous = true;
        content_area.valign = Gtk.Align.CENTER;

        content_area.attach (image, 0, 0, 1, 1);
        content_area.attach (title_label, 0, 1, 1, 1);
        content_area.attach (grid, 1, 0, 1, 2);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var demo_button = new Gtk.Button.with_label (_("Try Demo Mode"));

        var next_button = new Gtk.Button.with_label (_("Install %s").printf (Utils.get_pretty_name ()));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var shutdown_button = new Gtk.Button.from_icon_name ("system-shutdown-symbolic", Gtk.IconSize.BUTTON);
        shutdown_button.tooltip_text = _("Shut Down");
        shutdown_button.get_style_context ().add_class ("circular");

        action_area.add (shutdown_button);
        action_area.add (demo_button);
        action_area.add (back_button);
        action_area.add (next_button);
        action_area.set_child_secondary (shutdown_button, true);
        action_area.set_child_non_homogeneous (shutdown_button, true);

        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        demo_button.clicked.connect (Utils.demo_mode);

        next_button.clicked.connect (() => next_step ());

        shutdown_button.clicked.connect (() => {
            var end_session_dialog = new EndSessionDialog ();
            end_session_dialog.transient_for = (Gtk.Window) get_toplevel ();
            end_session_dialog.run ();
        });

        show_all ();
    }
}
