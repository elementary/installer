// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016 elementary LLC. (https://elementary.io)
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
    Gtk.Stack stack;
    public MainWindow () {
        
    }

    construct {
        deletable = false;
        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        get_content_area ().add (stack);
        var language_view = new LanguageView ();
        stack.add_named (language_view, "language");
        set_default_geometry (800, 600);

        language_view.next_step.connect ((lang) => load_checkview ());
    }
    
    private void load_checkview () {
        var check_view = new Installer.CheckView ();
        if (check_view.check_requirements ()) {
            load_diskview ();
        } else {
            check_view.next_step.connect (() => load_diskview ());
            check_view.cancel.connect (() => destroy ());
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
    }
}
