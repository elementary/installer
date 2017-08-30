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

    public MainWindow () {
        Object (deletable: false);
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
        stack.add_named (language_view, "language-view");
        stack.add_named (keyboard_layout_view, "keyboard-layout-view");
        stack.add_named (progress_view, "progress-view");
        stack.add_named (try_install_view, "try-install-view");
        stack.add_named (success_view, "success-view");
        stack.add_named (error_view, "error-view");

        title = _("Install %s").printf (Utils.get_pretty_name ());
        set_default_geometry (800, 600);
        get_content_area ().add (stack);

        check_view.next_step.connect (() => load_diskview ());
        check_view.cancel.connect (() => destroy ());

        try_install_view.next_step.connect (() => load_checkview());
        try_install_view.cancel.connect (() => destroy ());

        keyboard_layout_view.next_step.connect (() => stack.set_visible_child_name ("try-install-view"));

        language_view.next_step.connect ((lang) => {
            stack.set_visible_child_name ("keyboard-layout-view");
            keyboard_layout_view.set_language (lang);
        });
    }

    private void load_checkview () {
        if (check_view.check_requirements ()) {
            load_diskview ();
        } else {
            stack.add_named (check_view, "check");
            stack.set_visible_child_name ("check");
        }
    }

    private void load_diskview () {
        var disk_view = new DiskView ();
        disk_view.cancel.connect (() => destroy ());
        stack.add_named (disk_view, "disk");
        stack.set_visible_child_name ("disk");
        disk_view.load.begin ();

        disk_view.next_step.connect (() => {
            stack.set_visible_child_name ("progress-view");
        });
    }
}
