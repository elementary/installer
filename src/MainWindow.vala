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

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.add_named (language_view, "language");
        stack.add_named (keyboard_layout_view, "keyboard-layout");
        stack.add_named (progress_view, "progress-view");
        stack.add_named (try_install_view, "try-install-view");
        stack.add_named (success_view, "success-view");

        title = _("Install %s").printf (get_pretty_name ());
        set_default_geometry (800, 600);
        get_content_area ().add (stack);

        check_view.next_step.connect (() => load_diskview ());
        check_view.cancel.connect (() => destroy ());

        try_install_view.next_step.connect (() => load_checkview ());

        keyboard_layout_view.next_step.connect ((lang) => stack.set_visible_child_name ("try-install-view"));

        language_view.next_step.connect ((lang) => stack.set_visible_child_name ("keyboard-layout"));
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

    private static string get_pretty_name () {
        string pretty_name = _("Operating System");;
        const string ETC_OS_RELEASE = "/etc/os-release";

        try {
            var data_stream = new DataInputStream (File.new_for_path (ETC_OS_RELEASE).read ());

            string line;
            while ((line = data_stream.read_line (null)) != null) {
                var osrel_component = line.split ("=", 2);
                if (osrel_component.length == 2 && osrel_component[0] == "PRETTY_NAME") {
                    pretty_name = osrel_component[1].replace ("\"", "");
                    break;
                }
            }
        } catch (Error e) {
            warning ("Couldn't read os-release file: %s", e.message);
        }

        return pretty_name;
    }
}
