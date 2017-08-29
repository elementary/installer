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

public class TryInstallView : AbstractInstallerView {
    public signal void next_step ();

    construct {
        string os_name = Utils.get_pretty_name ();

        var title_label = new Gtk.Label (_("Install %s").printf (os_name));
        title_label.get_style_context ().add_class ("h1");
        title_label.valign = Gtk.Align.START;

        var description_label = new Gtk.Label (_("You can install %s on this device now, or cancel the installation to try it without installing.").printf (os_name));
        description_label.hexpand = true;
        description_label.margin_bottom = 12;
        description_label.wrap = true;
        description_label.max_width_chars = 60;
        description_label.halign = Gtk.Align.CENTER;

        var nochanges_label = new Gtk.Label (_("Data from your previous operating system is unchanged until you install.").printf (os_name));
        nochanges_label.wrap = true;

        var nochanges_image = new Gtk.Image.from_icon_name ("computer", Gtk.IconSize.DIALOG);
        nochanges_image.valign = Gtk.Align.START;

        var nochanges_emblem = new Gtk.Image.from_icon_name ("emblem-default", Gtk.IconSize.LARGE_TOOLBAR);
        nochanges_emblem.valign = Gtk.Align.END;
        nochanges_emblem.halign = Gtk.Align.END;

        var nochanges_overlay = new Gtk.Overlay ();
        nochanges_overlay.add_overlay (nochanges_image);
        nochanges_overlay.add_overlay (nochanges_emblem);
        nochanges_overlay.halign = Gtk.Align.CENTER;
        nochanges_overlay.height_request = 51;
        nochanges_overlay.width_request = 60;

        var nosaving_label = new Gtk.Label (_("Any changes you make before installing will not be saved.").printf (os_name));
        nosaving_label.valign = Gtk.Align.START;
        nosaving_label.wrap = true;
        nosaving_label.justify = Gtk.Justify.CENTER;

        var nosaving_image = new Gtk.Image.from_icon_name ("document-revert", Gtk.IconSize.DIALOG);
        nosaving_image.valign = Gtk.Align.START;

        var return_label = new Gtk.Label (_("If you cancel, you can always return to the installer by selecting the Install icon.").printf (os_name));
        return_label.valign = Gtk.Align.START;
        return_label.wrap = true;

        var return_image = new Gtk.Image.from_icon_name ("system-os-installer", Gtk.IconSize.DIALOG);
        return_image.valign = Gtk.Align.END;

        //var content_area = new Gtk.Grid ();
        content_area.column_homogeneous = true;
        content_area.vexpand = true;
        content_area.valign = Gtk.Align.CENTER;
        content_area.halign = Gtk.Align.CENTER;
        content_area.attach (title_label, 0, 0, 3, 1);
        content_area.attach (description_label, 0, 1, 3, 1);
        content_area.attach (nochanges_overlay, 0, 2, 1, 1);
        content_area.attach (nochanges_label, 0, 3, 1, 1);
        content_area.attach (nosaving_image, 1, 2, 1, 1);
        content_area.attach (nosaving_label, 1, 3, 1, 1);
        content_area.attach (return_image, 2, 2, 1, 1);
        content_area.attach (return_label, 2, 3, 1, 1);

        var next_button = new Gtk.Button.with_label (_("Install %s").printf (os_name));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_area.add (next_button);

        next_button.clicked.connect (() => next_step ());
    }
}
