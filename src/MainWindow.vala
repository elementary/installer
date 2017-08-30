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
    private CheckView check_view;
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
            resizable: false,
            title: _("Install %s").printf (Utils.get_pretty_name ()),
            width_request: 800
        );
    }

    construct {
        check_view = new Installer.CheckView ();
        var keyboard_layout_view = new KeyboardLayoutView ();
        var language_view = new LanguageView ();
        var progress_view = new ProgressView ();
        var try_install_view = new TryInstallView ();
        var success_view = new SuccessView ();
        var error_view = new ErrorView ();

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add_named (language_view, LANGUAGE_VIEW);
        stack.add_named (keyboard_layout_view, KEYBOARD_LAYOUT_VIEW);
        stack.add_named (try_install_view, TRY_INSTALL_VIEW);
        stack.add_named (progress_view, PROGRESS_VIEW);
        stack.add_named (success_view, SUCCESS_VIEW);
        stack.add_named (error_view, ERROR_VIEW);

        try_install_view.stack = stack;

        get_content_area ().add (stack);

        check_view.next_step.connect (() => load_diskview ());

        try_install_view.next_step.connect (() => load_checkview());

        keyboard_layout_view.next_step.connect (() => stack.set_visible_child_name (TRY_INSTALL_VIEW));

        language_view.next_step.connect ((lang) => {
            stack.set_visible_child_name (KEYBOARD_LAYOUT_VIEW);
            keyboard_layout_view.set_language (lang);
        });
    }

    private void load_checkview () {
        if (check_view.check_requirements ()) {
            load_diskview ();
        } else {
            stack.add_named (check_view, CHECK_VIEW);
            stack.set_visible_child_name (CHECK_VIEW);
        }
    }

    private void load_diskview () {
        var disk_view = new DiskView ();
        stack.add_named (disk_view, DISK_VIEW);
        stack.set_visible_child_name (DISK_VIEW);
        disk_view.load.begin ();

        disk_view.next_step.connect (() => {
            stack.set_visible_child_name (PROGRESS_VIEW);
        });
    }
}
