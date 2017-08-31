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

    public const string CHECK_VIEW = "check-view";
    public const string DISK_VIEW = "disk-view";
    public const string ERROR_VIEW = "error-view";
    public const string LANGUAGE_VIEW = "language-view";
    public const string KEYBOARD_LAYOUT_VIEW = "keyboard-layout-view";
    public const string PROGRESS_VIEW = "progress-view";
    public const string SUCCESS_VIEW = "success-view";
    public const string TRY_INSTALL_VIEW = "try-install-view";

    public MainWindow () {
        Object (
            deletable: false,
            height_request: 700,
            icon_name: "system-os-installer",
            resizable: false,
            title: _("Install %s").printf (Utils.get_pretty_name ()),
            width_request: 800
        );
    }

    construct {
        var language_view = new LanguageView ();

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add_named (language_view, LANGUAGE_VIEW);

        get_content_area ().add (stack);

        language_view.next_step.connect (() => load_keyboard_view ());
    }

    // We need to load all the view after the language has being chosen and set.

    private void load_keyboard_view () {
        var keyboard_layout_view = new KeyboardLayoutView ();
        stack.add_named (keyboard_layout_view, KEYBOARD_LAYOUT_VIEW);
        stack.visible_child = keyboard_layout_view;

        keyboard_layout_view.next_step.connect (() => load_try_install_view ());
    }

    private void load_try_install_view () {
        var try_install_view = new TryInstallView ();
        stack.add_named (try_install_view, TRY_INSTALL_VIEW);
        stack.visible_child = try_install_view;

        try_install_view.next_step.connect (() => load_checkview ());
    }

    private void load_checkview () {
        var check_view = new Installer.CheckView ();
        check_view.next_step.connect (() => load_diskview ());
        if (check_view.check_requirements ()) {
            load_diskview ();
        } else {
            stack.add_named (check_view, CHECK_VIEW);
            stack.visible_child = check_view;
        }
    }

    private void load_diskview () {
        var disk_view = new DiskView ();
        stack.add_named (disk_view, DISK_VIEW);
        stack.visible_child = disk_view;
        disk_view.load.begin ();

        disk_view.next_step.connect (() => load_progress_view ());
    }

    private void load_progress_view () {
        var progress_view = new ProgressView ();
        stack.add_named (progress_view, PROGRESS_VIEW);
        stack.visible_child = progress_view;

        progress_view.on_success.connect (() => load_success_view ());
        progress_view.on_error.connect (() => load_error_view ());
    }

    private void load_success_view () {
        var success_view = new SuccessView ();
        stack.add_named (success_view, SUCCESS_VIEW);
        stack.visible_child = success_view;
    }

    private void load_error_view () {
        var error_view = new ErrorView ();
        stack.add_named (error_view, ERROR_VIEW);
        stack.visible_child = error_view;
    }

    public override void close () {}
}
