/*-
 * Copyright 2017–2021 elementary, Inc. (https://elementary.io)
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
    public signal void custom_step ();
    public signal void next_step ();

    construct {
        var type_image = new Gtk.Image.from_icon_name (Application.get_default ().application_id, Gtk.IconSize.DIALOG) {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        var type_label = new Gtk.Label (_("Try or Install")) {
            valign = Gtk.Align.START
        };

        // Force the user to make a conscious selection, not spam "Next"
        var no_selection = new Gtk.RadioButton (null) {
            active = true
        };

        var demo_button = new InstallTypeButton (
            _("Try Demo Mode"),
            "dialog-question",
            _("Changes will not be saved, and data from your previous OS will be unchanged. Performance and features may not reflect the installed experience.")
        ) {
            group = no_selection
        };

        var clean_install_button = new InstallTypeButton (
            _("Erase Disk and Install"),
            "edit-clear",
            _("Erase everything and install a fresh copy of %s.").printf (Utils.get_pretty_name ())
        ) {
            group = no_selection
        };

        var custom_button = new InstallTypeButton (
            _("Custom Install (Advanced)"),
            "system-run",
            _("Create, resize, or otherwise manage partitions manually. This method may lead to data loss.")
        ) {
            group = no_selection
        };

        var type_box = new Gtk.Box (VERTICAL, 6) {
            valign = CENTER,
            vexpand = true
        };
        type_box.add (demo_button);
        type_box.add (clean_install_button);
        type_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        type_box.add (custom_button);

        var type_scrolled = new Gtk.ScrolledWindow (null, null) {
            child = type_box,
            hscrollbar_policy = NEVER,
            propagate_natural_height = true
        };

        title_area.add (type_image);
        title_area.add (type_label);

        content_area.add (type_scrolled);

        var back_button = new Gtk.Button.with_label (_("Back"));

        var next_button = new Gtk.Button.with_label (_("Next")) {
            sensitive = false
        };
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        action_box_end.add (back_button);
        action_box_end.add (next_button);

        back_button.clicked.connect (() => ((Hdy.Deck) get_parent ()).navigate (Hdy.NavigationDirection.BACK));

        demo_button.clicked.connect (() => {
            if (demo_button.active) {
                next_button.label = demo_button.title;
                next_button.sensitive = true;
            }
        });

        clean_install_button.clicked.connect (() => {
            if (clean_install_button.active) {
                next_button.label = clean_install_button.title;
                next_button.sensitive = true;
            }
        });

        custom_button.clicked.connect (() => {
            if (custom_button.active) {
                next_button.label = _("Custom Install");
                next_button.sensitive = true;
            }
        });

        next_button.clicked.connect (() => {
            if (demo_button.active) {
                Utils.demo_mode ();
            } else if (clean_install_button.active) {
                next_step ();
            } else if (custom_button.active) {
                custom_step ();
            }
        });

        show_all ();
    }
}
