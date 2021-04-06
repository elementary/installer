/*
 * Copyright 2021 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

public class AutomatedView : AbstractInstallerView {
    public signal void on_success ();
    public signal void on_error ();

    private unowned Configuration config;

    construct {
        config = Configuration.get_default ();

        var logo = new Gtk.Image ();
        logo.icon_name = "distributor-logo";
        logo.pixel_size = 128;
        logo.get_style_context ().add_class ("logo");

        var logo_stack = new Gtk.Stack ();
        logo_stack.transition_type = Gtk.StackTransitionType.OVER_UP_DOWN;
        logo_stack.add (logo);

        content_area.margin_end = 22;
        content_area.margin_start = 22;
        content_area.attach (logo_stack, 0, 0, 2, 1);

        get_style_context ().add_class ("progress-view");

        show_all ();
    }

    public string get_log () {
        return "";
    }

    public void start () {
        var cmdline = Utils.get_kernel_parameters ();
        if ("auto" in cmdline) {
            for (int i = 0; i < cmdline.length; i++) {
                if ("url=" in cmdline[i]) {
                    var uri = cmdline[i].split ("=")[1].strip ();

                    var server_file = File.new_for_uri (uri);
                    var path = Path.build_filename (Environment.get_tmp_dir (), server_file.get_basename ());
                    var local_file = File.new_for_path (path);

                    bool result = false;
                    try {
                        result = server_file.copy (local_file, FileCopyFlags.OVERWRITE, null, (current_num_bytes, total_num_bytes) => {
                        });
                    } catch (Error e) {
                        warning ("Could not download configuration file from \"%s\": %s", uri, e.message);
                        on_error ();
                    }

                    if (result) {
                        Installer.App.config_file = path;
                    }
                }
            }
        }

        if (Installer.App.config_file != null) {
            try {
                debug ("Loading config from \"%s\"", Installer.App.config_file);

                string config_string;
                FileUtils.get_contents (Installer.App.config_file, out config_string);
                config = new Configuration.from_string (config_string);

                on_success ();
                return;
            } catch (Error e) {
                warning ("Could not read config file '%s': %s", Installer.App.config_file, e.message);
                on_error ();
            }
        }

        on_error ();
    }
}
