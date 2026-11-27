/*
 * Copyright 2021-2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[DBus (name = "io.elementary.InstallerDaemon")]
public class InstallerDaemon.CommonBackend : GLib.Object {
    public void set_demo_mode_locale (string locale) throws GLib.Error {
        GLib.FileUtils.set_contents ("/etc/default/locale", "LANG=" + locale);
    }

    public void trigger_demo_mode () throws GLib.Error {
        var demo_mode_file = GLib.File.new_for_path ("/var/lib/lightdm/demo-mode");
        try {
            demo_mode_file.create (GLib.FileCreateFlags.NONE);
        } catch (GLib.Error e) {
            if (!(e is GLib.IOError.EXISTS)) {
                throw e;
            }
        }
    }
}
