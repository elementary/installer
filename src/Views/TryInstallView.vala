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

public class Installer.TryInstallView : AbstractInstallerView {
    public signal void alongside_step ();
    public signal void custom_step ();
    public signal void next_step ();
    public signal void refresh_step ();

    private Gtk.Button next_button;

    construct {
        var type_grid = new Gtk.Grid ();
        type_grid.halign = Gtk.Align.CENTER;
        type_grid.valign = Gtk.Align.CENTER;
        type_grid.orientation = Gtk.Orientation.VERTICAL;
        type_grid.vexpand = true;
        type_grid.row_spacing = 6;

        var type_scrolled = new Gtk.ScrolledWindow (null, null);
        type_scrolled.vexpand = true;
        type_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
#if GTK_3_22
        type_scrolled.propagate_natural_height = true;
#endif
        type_scrolled.add (type_grid);

        var type_image = new Gtk.Image.from_icon_name ("system-os-installer", Gtk.IconSize.DIALOG);
        type_image.valign = Gtk.Align.START;

        var type_label = new Gtk.Label (_("Install"));
        type_label.hexpand = true;
        type_label.get_style_context ().add_class ("h2");
        type_label.margin_bottom = 18;

        var artwork = new Gtk.Grid ();
        artwork.get_style_context ().add_class ("try-install");
        artwork.get_style_context ().add_class ("artwork");
        artwork.vexpand = true;

        var content_overlay = new Gtk.Overlay ();

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.margin_top = 24;
        grid.valign = Gtk.Align.FILL;
        grid.column_homogeneous = true;
        grid.attach (artwork,       0, 0);
        grid.attach (type_label,    0, 1);
        grid.attach (type_scrolled, 1, 0, 1, 2);

        content_overlay.add (grid);
        content_area.margin = 0;
        content_area.valign = Gtk.Align.FILL;
        content_area.column_homogeneous = true;
        content_area.attach (content_overlay, 0, 0);

        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.clicked.connect (() => ((Gtk.Stack) get_parent ()).visible_child = previous_view);

        key_press_event.connect ((event) => {
            switch (event.keyval) {
                case Gdk.Key.Left:
                    if (event.state != Gdk.ModifierType.MOD1_MASK) {
                        break;
                    }
                case Gdk.Key.Escape:
                    back_button.clicked ();
                    return true;
            }

            return false;
        });

        next_button = new Gtk.Button.with_label (_("Next"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.sensitive = false;

        var demo_button = new Gtk.Button.with_label (_("Try Demo Mode"));
        demo_button.clicked.connect (Utils.demo_mode);

        var button_creator = new InstallButtonFactory (next_button, type_grid);
        string pretty_name = Utils.get_pretty_name ();

        var clean_install_button = button_creator.new_button (
            _("Clean Install"),
            "system-os-installer",
            _("Erase everything and install a fresh copy of %s.").printf (pretty_name),
            () => next_step ()
        );

        var refresh_install_button = button_creator.new_button (
            _("Refresh Install"),
            "view-refresh",
            _("Reinstall while keeping user accounts and files. Applications will need to be reinstalled manually."),
            () => refresh_step ()
        );

        //  var alongside_button = button_creator.new_button (
        //      _("Install Alongside OS"),
        //      "drive-multidisk",
        //      _("Install %s next to one or more existing OS installations").printf (pretty_name),
        //      () => alongside_step ()
        //  );

        var custom_button = button_creator.new_button (
            _("Custom (Advanced)"),
            "disk-utility",
            _("Create, resize, or otherwise manage partitions manually. This method may lead to data loss."),
            () => custom_step ()
        );

        action_area.add (back_button);
        action_area.add (next_button);
        action_area.add (demo_button);
        action_area.homogeneous = false;
        action_area.set_child_secondary (demo_button, true);
        action_area.set_child_non_homogeneous (demo_button, true);

        var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
        sizegroup.add_widget (clean_install_button.type_image);
        sizegroup.add_widget (refresh_install_button.type_image);
        //  sizegroup.add_widget (alongside_button.type_image);
        sizegroup.add_widget (custom_button.type_image);

        type_grid.add (clean_install_button);
        type_grid.add (refresh_install_button);
        //  type_grid.add (alongside_button);
        type_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        type_grid.add (custom_button);

        demo_button.key_press_event.connect ((event) => handle_key_press (demo_button, event));
        clean_install_button.key_press_event.connect ((event) => handle_key_press (clean_install_button, event));
        refresh_install_button.key_press_event.connect ((event) => handle_key_press (refresh_install_button, event));
        //  alongside_button.key_press_event.connect ((event) => handle_key_press (alongside_button, event));
        custom_button.key_press_event.connect ((event) => handle_key_press (custom_button, event));

        var options = InstallOptions.get_default ();

        show_all ();

        clean_install_button.grab_focus ();

        refresh_install_button.visible = options.get_options ().has_refresh_options ();
        //  alongside_button.visible = options.get_options ().has_alongside_options ();
    }

    private bool handle_key_press (Gtk.Button button, Gdk.EventKey event) {
        if (event.keyval == Gdk.Key.Return) {
            button.clicked ();
            next_button.clicked ();
            return true;
        }

        return false;
    }
}
