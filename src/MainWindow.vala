// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016-2017 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Installer.MainWindow : Gtk.Dialog {
    private Gtk.Stack stack;

    private LanguageView language_view;
    private KeyboardLayoutView keyboard_layout_view;
    private TryInstallView try_install_view;
    private Installer.CheckView check_view;
    private DiskView disk_view;
    private ProgressView progress_view;
    private SuccessView success_view;
    private EncryptView encrypt_view;
    private ErrorView error_view;
    private bool check_ignored = false;

    private uint64 minimum_disk_size;

    public MainWindow () {
        Object (
            deletable: false,
            height_request: 700,
            icon_name: "system-os-installer",
            resizable: false,
            title: _("Install %s").printf (Utils.get_pretty_name ()),
            width_request: 950
        );
    }

    construct {
        language_view = new LanguageView ();

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add (language_view);

        get_content_area ().add (stack);
        get_style_context ().add_class ("os-installer");

        minimum_disk_size = Distinst.minimum_disk_size (5000000000);

        language_view.next_step.connect (() => load_keyboard_view ());
    }

    /*
     * We need to load all the view after the language has being chosen and set.
     * We need to rebuild the view everytime the next button is clicked to reflect language changes.
     */

    private void load_keyboard_view () {
        if (keyboard_layout_view != null) {
            keyboard_layout_view.destroy ();
        }

        keyboard_layout_view = new KeyboardLayoutView ();
        keyboard_layout_view.previous_view = language_view;
        stack.add (keyboard_layout_view);
        stack.visible_child = keyboard_layout_view;

        keyboard_layout_view.next_step.connect (() => load_try_install_view ());
    }

    private void load_try_install_view () {
        if (try_install_view != null) {
            try_install_view.destroy ();
        }

        try_install_view = new TryInstallView ();
        try_install_view.previous_view = keyboard_layout_view;
        stack.add (try_install_view);
        stack.visible_child = try_install_view;

        try_install_view.next_step.connect (() => load_checkview ());
    }

    private void load_checkview () {
        if (check_view != null) {
            check_view.destroy ();
        }

        check_view = new Installer.CheckView (minimum_disk_size);
        check_view.previous_view = try_install_view;
        stack.add (check_view);
        if (check_ignored || check_view.check_requirements ()) {
            load_encryptview ();
        } else {
            stack.visible_child = check_view;
        }

        check_view.next_step.connect (() => {
            check_ignored = true;
            load_encryptview ();
        });

        check_view.status_changed.connect ((met_requirements) => {
            if (!check_ignored) {
                if (!met_requirements) {
                    check_view.previous_view = stack.visible_child;
                    stack.visible_child = check_view;
                } else {
                    stack.visible_child = check_view.previous_view;
                    check_view.previous_view = try_install_view;
                }
            }
        });
    }

    private void load_encryptview () {
        if (encrypt_view != null) {
            encrypt_view.destroy ();
        }

        encrypt_view = new EncryptView ();
        encrypt_view.previous_view = try_install_view;
        stack.add (encrypt_view);
        stack.visible_child = encrypt_view;

        encrypt_view.next_step.connect (() => load_diskview ());
    }

    private void load_diskview () {
        if (disk_view != null) {
            disk_view.destroy ();
        }

        disk_view = new DiskView ();
        disk_view.previous_view = try_install_view;
        stack.add (disk_view);
        stack.visible_child = disk_view;
        disk_view.load.begin(minimum_disk_size);

        disk_view.next_step.connect (() => load_progress_view ());
    }

    private void load_progress_view () {
        if (progress_view != null) {
            progress_view.destroy ();
        }

        progress_view = new ProgressView ();
        stack.add (progress_view);
        stack.visible_child = progress_view;

        progress_view.on_success.connect (() => load_success_view ());
        progress_view.on_error.connect (() => load_error_view ());
        progress_view.start_installation ();
    }

    private void load_success_view () {
        if (success_view != null) {
            success_view.destroy ();
        }

        success_view = new SuccessView ();
        stack.add (success_view);
        stack.visible_child = success_view;
    }

    private void load_error_view () {
        if (error_view != null) {
            error_view.destroy ();
        }

        error_view = new ErrorView ();
        stack.add (error_view);
        stack.visible_child = error_view;

        error_view.previous_view = disk_view;
    }

    public override void close () {}
}
