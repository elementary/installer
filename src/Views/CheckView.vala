/*-
 * Copyright 2016-2022 elementary, Inc. (https://elementary.io)
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

public class Installer.CheckView : AbstractInstallerView {
    // We have to do it step by step because the vala compiler has overflows with big numbers.
    public const uint64 ONE_GB = 1000 * 1000 * 1000;
    // Minimum 1.2 GHz
    public const int MINIMUM_FREQUENCY = 1200 * 1000;
    // Minimum 1GB
    public const uint64 MINIMUM_MEMORY = 1 * ONE_GB;

    private Gtk.ListBox message_box;
    public bool has_messages {
        get {
            return message_box.get_row_at_index (0) != null;
        }
    }

    private int frequency = 0;
    private uint64 memory = 0;

    public CheckView () {
        Object (cancellable: true);
    }

    construct {
        var image = new Gtk.Image.from_icon_name ("io.elementary.installer.caution") {
            pixel_size = 128,
            valign = Gtk.Align.END
        };

        title = _("Before Installing");

        var title_label = new Gtk.Label (title) {
            valign = Gtk.Align.START
        };

        var beta_view = new CheckView (
            _("Pre-Release Version"),
            _("Only install on devices dedicated for development. <b>You will not be able to upgrade to a stable release</b>."),
            "applications-development"
        );

        var vm_view = new CheckView (
            _("Virtual Machine"),
            _("Some parts of %s may run slowly, freeze, or not function properly.").printf (Utils.get_pretty_name ()),
            "computer-fail"
        );

        var specs_view = new CheckView (
            _("Your Device May Be Too Slow"),
            _("This may cause it to run slowly or freeze."),
            "application-x-firmware"
        );
        specs_view.attach (get_comparison_grid (), 1, 2);

        message_box = new Gtk.ListBox () {
            selection_mode = BROWSE,
            valign = CENTER,
            vexpand = true
        };
        message_box.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        message_box.add_css_class (Granite.STYLE_CLASS_BACKGROUND);

        title_area.append (image);
        title_area.append (title_label);

        content_area.append (message_box);

        var ignore_button = new Gtk.Button.with_label (_("Install Anyway"));
        ignore_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
        ignore_button.clicked.connect (() => next_step ());

        action_box_end.append (ignore_button);

        bool minimum_specs = true;

        frequency = get_frequency ();
        if (frequency < MINIMUM_FREQUENCY && frequency > 0) {
            minimum_specs = false;
        }

        memory = get_mem_info ();
        if (memory < MINIMUM_MEMORY) {
            minimum_specs = false;
        }

        var apt_sources = File.new_for_path ("/etc/apt/sources.list.d/elementary.list");
        try {
            var @is = apt_sources.read ();
            var dis = new DataInputStream (@is);

            if ("daily" in dis.read_line () || Installer.App.test_mode) {
                message_box.append (beta_view);
            }
        } catch (Error e) {
            critical ("Couldn't read apt sources: %s", e.message);
        }

        if (get_vm () || Installer.App.test_mode) {
            message_box.append (vm_view);
        }

        if (!minimum_specs || Installer.App.test_mode) {
            message_box.append (specs_view);
        }
    }

    private int get_frequency () {
        var max_freq_file = GLib.File.new_for_path ("/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq");
        try {
            FileInputStream @is = max_freq_file.read ();
            DataInputStream dis = new DataInputStream (@is);
            string line;

            while ((line = dis.read_line ()) != null) {
                return int.parse (line);
            }
        } catch (Error e) {
            stdout.printf ("Error: %s\n", e.message);
        }

        return 0;
    }

    private uint64 get_mem_info () {
        File file = File.new_for_path ("/proc/meminfo");
        try {
            DataInputStream dis = new DataInputStream (file.read ());
            string? line;
            string name = "MemTotal:";
            while ((line = dis.read_line (null, null)) != null) {
                if (line.has_prefix (name)) {
                    var number = line.replace ("kB", "").replace (name, "").strip ();
                    return uint64.parse (number) * 1000;
                }
            }
        } catch (Error e) {
            warning (e.message);
        }

        return 0;
    }

    private static bool get_vm () {
        File file = File.new_for_path ("/proc/cpuinfo");
        try {
            DataInputStream dis = new DataInputStream (file.read ());
            string? line;
            while ((line = dis.read_line (null, null)) != null) {
                if (line.has_prefix ("flags") && line.contains ("hypervisor")) {
                    return true;
                }
            }
        } catch (Error e) {
            critical (e.message);
        }

        return false;
    }

    private class CheckView : Gtk.Grid {
        public string title { get; construct; }
        public string description { get; construct; }
        public string icon_name { get; construct; }

        private Gtk.Grid grid;

        public CheckView (string title, string description, string icon_name) {
            Object (
                title: title,
                description: description,
                icon_name: icon_name
            );
        }

        construct {
            var image = new Gtk.Image.from_icon_name (icon_name) {
                icon_size = LARGE,
                valign = START
            };

            var title_label = new Gtk.Label (title) {
                wrap = true,
                xalign = 0
            };
            title_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

            var description_label = new Gtk.Label (description) {
                use_markup = true,
                wrap = true,
                xalign = 0
            };

            column_spacing = 12;
            attach (image, 0, 0, 1, 2);
            attach (title_label, 1, 0);
            attach (description_label, 1, 1);

            // prevent reading all descriptions immediately
            title_label.set_accessible_role (PRESENTATION);
            description_label.set_accessible_role (PRESENTATION);

            // prevent titles from being skipped
            map.connect (() => {
                parent.update_property (
                    Gtk.AccessibleProperty.LABEL, title,
                    Gtk.AccessibleProperty.DESCRIPTION, description,
                    -1
                );
            });
        }
    }

    private Gtk.Grid get_comparison_grid () {
        var recommended_label = new Gtk.Label (_("Recommended:")) {
            hexpand = true,
            xalign = 0
        };
        recommended_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        var your_device_label = new Gtk.Label (_("Your Device:")) {
            hexpand = true,
            xalign = 0
        };
        your_device_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        var processor_1 = new Gtk.Label (_("Processor:")) {
            xalign = 1
        };

        var processor_2 = new Gtk.Label (_("Processor:")) {
            xalign = 1
        };

        var processor_val_1 = new Gtk.Label (get_frequency_string (MINIMUM_FREQUENCY)) {
            xalign = 0
        };

        var processor_val_2 = new Gtk.Label (get_frequency_string (frequency)) {
            xalign = 0
        };

        var memory_1 = new Gtk.Label (_("Memory:")) {
            xalign = 1
        };

        var memory_2 = new Gtk.Label (_("Memory:")) {
            xalign = 1
        };

        var memory_val_1 = new Gtk.Label (GLib.format_size (MINIMUM_MEMORY)) {
            xalign = 0
        };

        var memory_val_2 = new Gtk.Label (GLib.format_size (memory)) {
            xalign = 0
        };

        var comparison_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_top = 12,
            row_spacing = 6
        };
        comparison_grid.attach (recommended_label, 0, 0, 2);
        comparison_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 2, 0, 1, 5);
        comparison_grid.attach (your_device_label, 3, 0, 2, 1);
        comparison_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 1, 5);
        comparison_grid.attach (processor_1, 0, 2);
        comparison_grid.attach (processor_val_1, 1, 2);
        comparison_grid.attach (processor_2, 3, 2);
        comparison_grid.attach (processor_val_2, 4, 2);
        comparison_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 3, 5);
        comparison_grid.attach (memory_1, 0, 4);
        comparison_grid.attach (memory_val_1, 1, 4);
        comparison_grid.attach (memory_2, 3, 4);
        comparison_grid.attach (memory_val_2, 4, 4);

        return comparison_grid;
    }

    private static string get_frequency_string (int freq) {
        if (freq >= 1000000) {
            return "%.1f GHz".printf (((float)freq) / 1000000);
        } else if (freq >= 1000) {
            return "%.1f MHz".printf (((float)freq) / 1000);
        } else {
            return "%d kHz".printf (freq);
        }
    }
}
