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

public class Installer.MainWindow : Gtk.Window {
    private Gtk.Stack stack;

    private LanguageView language_view;
    private KeyboardLayoutView keyboard_layout_view;
    private TryInstallView try_install_view;
    private Installer.CheckView check_view;
    private DiskView disk_view;
    private PartitioningView partitioning_view;
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
        stack = new Gtk.Stack ();
        stack.margin_bottom = 12;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Grid ()); // null title workaround

        add (stack);
        get_style_context ().add_class ("rounded");
        set_titlebar (titlebar);

        minimum_disk_size = Distinst.minimum_disk_size (5000000000);

        switch (Installer.App.load_view) {
            case "keyboard":
                debug (_("Force loading keyboard view…"));
                load_keyboard_view ();
                break;

            case "try_install":
                debug (_("Force loading try/install view…"));
                load_try_install_view ();
                break;

            case "check":
                debug (_("Force loading check view…"));
                load_check_view ();
                break;

            case "disk":
                debug (_("Force loading disk view…"));
                load_disk_view ();
                break;

            case "partitioning":
                debug (_("Force loading partitioning view…"));
                load_partitioning_view ();
                break;

            case "progress":
                debug (_("Force loading progress view…"));
                load_progress_view ();
                break;

            case "success":
                debug (_("Force loading success view…"));
                load_success_view ();
                break;

            case "encrypt":
                debug (_("Force loading encrypt view…"));
                load_encrypt_view ();
                break;

            case "error":
                debug (_("Force loading error view…"));
                load_error_view ("");
                break;

            default:
                language_view = new LanguageView ();
                stack.add (language_view);
                language_view.next_step.connect (() => load_keyboard_view ());
        }
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

        try_install_view.custom_step.connect (() => load_partitioning_view ());
        try_install_view.next_step.connect (() => load_disk_view ());
    }

    private void set_check_view_visible (bool show) {
        if (show) {
            check_view.previous_view = stack.visible_child;
            stack.visible_child = check_view;
        } else if (check_view.previous_view != null) {
            stack.visible_child = check_view.previous_view;
            check_view.previous_view = null;
        }
    }

    private void load_check_view () {
        if (check_view != null) {
            check_view.destroy ();
        }

        check_view = new Installer.CheckView (minimum_disk_size);
        stack.add (check_view);

        check_view.status_changed.connect ((met_requirements) => {
            if (!check_ignored) {
                set_check_view_visible (!met_requirements);
            }
        });

        check_view.cancel.connect (() => {
            stack.visible_child = try_install_view;
            check_view.previous_view = null;
            check_view.destroy ();
        });

        check_view.next_step.connect (() => {
            check_ignored = true;
            set_check_view_visible (false);
        });

        set_check_view_visible (!check_ignored && !check_view.check_requirements ());
    }

    private void load_encrypt_view () {
        if (encrypt_view != null) {
            encrypt_view.destroy ();
        }

        encrypt_view = new EncryptView ();
        encrypt_view.previous_view = disk_view;
        stack.add (encrypt_view);
        stack.visible_child = encrypt_view;

        load_check_view ();

        encrypt_view.cancel.connect (() => {
            stack.visible_child = try_install_view;
        });

        encrypt_view.next_step.connect (() => load_progress_view ());
    }

    private void load_disk_view () {
        if (disk_view != null) {
            disk_view.destroy ();
        }

        disk_view = new DiskView ();
        disk_view.previous_view = try_install_view;
        stack.add (disk_view);
        stack.visible_child = disk_view;
        disk_view.load.begin (minimum_disk_size);

        disk_view.cancel.connect (() => {
            stack.visible_child = try_install_view;
        });

        disk_view.next_step.connect (() => load_encrypt_view ());
    }

    private void load_partitioning_view () {
        if (partitioning_view != null) {
            partitioning_view.destroy ();
        }

        partitioning_view = new PartitioningView (minimum_disk_size);
        partitioning_view.previous_view = try_install_view;
        stack.add (partitioning_view);
        stack.visible_child = partitioning_view;

        partitioning_view.next_step.connect (() => {
            unowned Configuration config = Configuration.get_default ();
            config.luks = (owned) partitioning_view.luks;
            config.mounts = (owned) partitioning_view.mounts;
            load_progress_view ();
        });
    }

    private void load_progress_view () {
        if (progress_view != null) {
            progress_view.destroy ();
        }

        progress_view = new ProgressView ();
        stack.add (progress_view);
        stack.visible_child = progress_view;

        progress_view.on_success.connect (() => load_success_view ());

        progress_view.on_error.connect (() => {
            load_error_view (progress_view.get_log ());
        });
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

    private void load_error_view (string log) {
        if (error_view != null) {
            error_view.destroy ();
        }

        error_view = new ErrorView (log);
        stack.add (error_view);
        stack.visible_child = error_view;

        error_view.previous_view = disk_view;
    }
}
