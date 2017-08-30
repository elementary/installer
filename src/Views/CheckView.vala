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

public class Installer.CheckView : Gtk.Stack {
    // We have to do it step by step because the vala compiler has overflows with big numbers.
    public static uint64 ONE_GB = 1000 * 1000 * 1000;
    // Minimum 5 GB
    public static uint64 MINIMUM_SPACE = 5 * ONE_GB;
    // Minimum 1.2 GHz
    public static int MINIMUM_FREQUENCY = 1200 * 1000;
    // Minimum 1GB
    public static uint64 MINIMUM_MEMORY = 1 * ONE_GB;

    public signal void next_step ();
    public signal void cancel ();

    bool enough_space = true;
    bool enough_power = true;
    bool powered = true;

    int frequency = 0;
    uint64 memory = 0;

    enum State {
        NONE,
        SPACE,
        SPECS,
        POWERED
    }

    State current_state = State.NONE;

    public CheckView () {
        show_all ();
    }

    construct {
        transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
    }

    // If all the requirements are met, skip this view (return true);
    public bool check_requirements () {
        enough_space = get_has_enough_space ();

        frequency = get_frequency ();
        if (frequency < MINIMUM_FREQUENCY && frequency > 0) {
            enough_power = false;
        }

        memory = get_mem_info ();
        if (memory < MINIMUM_MEMORY) {
            enough_power = false;
        }

        powered = !get_is_on_battery ();

        bool result = enough_space && enough_power && powered;
        if (result == false) {
            show_next ();
        }
        return result;
    }

    private static bool get_has_enough_space () {
        bool enough_space = false;
        try {
            var client = new DBusObjectManagerClient.for_bus_sync (BusType.SYSTEM, GLib.DBusObjectManagerClientFlags.NONE,
                                                            "org.freedesktop.UDisks2", "/org/freedesktop/UDisks2", null);
            client.get_objects ().foreach ((object) => {
                var drive_interface = object.get_interface ("org.freedesktop.UDisks2.Drive");
                if (drive_interface != null) {
                    try {
                        UDisks2.Drive drive = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.UDisks2", object.get_object_path ());
                        if (drive.removable) {
                            return;
                        }

                        enough_space |= drive.size > MINIMUM_SPACE;
                    } catch (Error e) {
                        warning (e.message);
                    }
                }
            });
        } catch (Error e) {
            critical (e.message);
        }
        return enough_space;
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
            while ((line = dis.read_line (null,null)) != null) {
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

    private bool get_is_on_battery () {
        try {
            UPower upower = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.UPower", "/org/freedesktop/UPower");
            return upower.on_battery;
        } catch (Error e) {
            warning (e.message);
        }

        return false;
    }

    private void show_next () {
        State next_state = State.NONE;
        switch (current_state) {
            case State.NONE:
                if (!enough_space) {
                    next_state = State.SPACE;
                } else if (!enough_power) {
                    next_state = State.SPECS;
                } else if (!powered) {
                    next_state = State.POWERED;
                } else {
                    next_step ();
                    return;
                }

                break;
            case State.SPACE:
                if (!enough_power) {
                    next_state = State.SPECS;
                } else if (!powered) {
                    next_state = State.POWERED;
                } else {
                    next_step ();
                    return;
                }

                break;
            case State.SPECS:
                if (!powered) {
                    next_state = State.POWERED;
                } else {
                    next_step ();
                    return;
                }

                break;
            case State.POWERED:
                next_step ();
                return;
        }

        switch (next_state) {
            case State.SPACE:
                var grid = setup_grid (_("Not Enough Space"), _("There is not enough room on your device to install elementary. We recommend a minimum of %s of storage.".printf (GLib.format_size (MINIMUM_SPACE))), "drive-harddisk");
                var cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
                cancel_button.clicked.connect (() => cancel ());
                cancel_button.halign = Gtk.Align.END;
                cancel_button.valign = Gtk.Align.END;
                cancel_button.margin_end = 6;
                var out_grid = new Gtk.Grid ();
                out_grid.expand = true;
                out_grid.orientation = Gtk.Orientation.VERTICAL;
                out_grid.add (grid);
                out_grid.add (cancel_button);
                add (out_grid);
                out_grid.show_all ();
                set_visible_child (out_grid);
                break;
            case State.SPECS:
                var grid = setup_grid (_("Your Device May Be Too Slow"), _("Your device doesn't meet the recommended hardware requirements. This may cause it to run slowly or freeze."), "application-x-firmware");
                var comparison_grid = get_comparison_grid ();
                grid.attach (comparison_grid, 1, 2, 1, 1);
                var ignore_button = new Gtk.Button.with_label (_("Ignore"));
                ignore_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                ignore_button.clicked.connect (() => show_next ());
                var cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
                cancel_button.clicked.connect (() => cancel ());
                var button_grid = new Gtk.Grid ();
                button_grid.column_homogeneous = true;
                button_grid.column_spacing = 6;
                button_grid.halign = Gtk.Align.END;
                button_grid.valign = Gtk.Align.END;
                button_grid.margin_end = 6;
                button_grid.add (cancel_button);
                button_grid.add (ignore_button);
                var out_grid = new Gtk.Grid ();
                out_grid.expand = true;
                out_grid.orientation = Gtk.Orientation.VERTICAL;
                out_grid.add (grid);
                out_grid.add (button_grid);
                add (out_grid);
                out_grid.show_all ();
                set_visible_child (out_grid);
                break;
            case State.POWERED:
                var grid = setup_grid (_("Connect to a Power Source"), _("Your device is running on battery power. It's recommended to be plugged in while installing."), "battery-ac-adapter");
                var ignore_button = new Gtk.Button.with_label (_("Ignore"));
                ignore_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                ignore_button.clicked.connect (() => show_next ());
                var cancel_button = new Gtk.Button.with_label (_("Cancel Installation"));
                cancel_button.clicked.connect (() => cancel ());
                var button_grid = new Gtk.Grid ();
                button_grid.column_homogeneous = true;
                button_grid.column_spacing = 6;
                button_grid.halign = Gtk.Align.END;
                button_grid.valign = Gtk.Align.END;
                button_grid.margin_end = 6;
                button_grid.add (cancel_button);
                button_grid.add (ignore_button);
                var out_grid = new Gtk.Grid ();
                out_grid.expand = true;
                out_grid.orientation = Gtk.Orientation.VERTICAL;
                out_grid.add (grid);
                out_grid.add (button_grid);
                add (out_grid);
                out_grid.show_all ();
                set_visible_child (out_grid);
                break;
        }

        current_state = next_state;
    }
    
    private Gtk.Grid setup_grid (string title, string description, string icon_name) {
        var title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("h2");
        title_label.wrap = true;
        title_label.max_width_chars = 60;
        title_label.xalign = 0;
        title_label.valign = Gtk.Align.END;

        var description_label = new Gtk.Label (description);
        description_label.wrap = true;
        description_label.max_width_chars = 60;
        description_label.xalign = 0;
        description_label.valign = Gtk.Align.START;

        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        image.valign = Gtk.Align.START;

        var grid = new Gtk.Grid ();
        grid.expand = true;
        grid.vexpand = true;
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.margin = 48;
        grid.halign = Gtk.Align.CENTER;
        grid.valign = Gtk.Align.CENTER;
        grid.attach (image, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0, 1, 1);
        grid.attach (description_label, 1, 1, 1, 1);

        return grid;
    }

    private Gtk.Grid get_comparison_grid () {
        var comparison_grid = new Gtk.Grid ();
        comparison_grid.column_spacing = 6;
        comparison_grid.row_spacing = 6;
        comparison_grid.margin_top = 12;
        var recommended_label = new Gtk.Label (_("Recommended:"));
        recommended_label.hexpand = true;
        recommended_label.get_style_context ().add_class ("category-label");
        recommended_label.xalign = 0;
        var your_device_label = new Gtk.Label (_("Your Device:"));
        your_device_label.hexpand = true;
        your_device_label.get_style_context ().add_class ("category-label");
        your_device_label.xalign = 0;
        var processor_1 = new Gtk.Label (_("Processor:"));
        processor_1.xalign = 1;
        var processor_2 = new Gtk.Label (_("Processor:"));
        processor_2.xalign = 1;
        var processor_val_1 = new Gtk.Label (get_frequency_string (MINIMUM_FREQUENCY));
        processor_val_1.xalign = 0;
        var processor_val_2 = new Gtk.Label (get_frequency_string (frequency));
        processor_val_2.xalign = 0;
        var memory_1 = new Gtk.Label (_("Memory:"));
        memory_1.xalign = 1;
        var memory_2 = new Gtk.Label (_("Memory:"));
        memory_2.xalign = 1;
        var memory_val_1 = new Gtk.Label (GLib.format_size (MINIMUM_MEMORY));
        memory_val_1.xalign = 0;
        var memory_val_2 = new Gtk.Label (GLib.format_size (memory));
        memory_val_2.xalign = 0;
        comparison_grid.attach (recommended_label, 0, 0, 2, 1);
        comparison_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 2, 0, 1, 5);
        comparison_grid.attach (your_device_label, 3, 0, 2, 1);
        comparison_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 1, 5, 1);
        comparison_grid.attach (processor_1, 0, 2, 1, 1);
        comparison_grid.attach (processor_val_1, 1, 2, 1, 1);
        comparison_grid.attach (processor_2, 3, 2, 1, 1);
        comparison_grid.attach (processor_val_2, 4, 2, 1, 1);
        comparison_grid.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 3, 5, 1);
        comparison_grid.attach (memory_1, 0, 4, 1, 1);
        comparison_grid.attach (memory_val_1, 1, 4, 1, 1);
        comparison_grid.attach (memory_2, 3, 4, 1, 1);
        comparison_grid.attach (memory_val_2, 4, 4, 1, 1);
        return comparison_grid;
    }
    
    private static string get_frequency_string (int freq) {
        if (freq >= 1000000) {
            return "%.1f GHz".printf (((float)freq)/1000000);
        } else if (freq >= 1000) {
            return "%.1f MHz".printf (((float)freq)/1000);
        } else {
            return "%d kHz".printf (freq);
        }
    }
}



[DBus (name = "org.freedesktop.UPower")]
public interface UPower : GLib.Object {
	public abstract bool on_battery { owned get; set; }
}
