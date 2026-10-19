/*
 * Copyright 2021-2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class InstallerDaemon.Application : GLib.Application {
    public Application () {
        Object (
            application_id: "io.elementary.InstallerDaemon",
            flags: ApplicationFlags.IS_SERVICE | ApplicationFlags.ALLOW_REPLACEMENT
        );
    }

    protected override bool dbus_register (DBusConnection connection, string object_path) throws GLib.Error {
        base.dbus_register (connection, object_path);

        try {
            connection.register_object ("/io/elementary/InstallerDaemon", new InstallerDaemon.CommonBackend ());
    #if DISTINST_BACKEND
            connection.register_object ("/io/elementary/InstallerDaemon", new InstallerDaemon.DistinstBackend ());
    #endif
        } catch (GLib.Error e) {
            critical ("Unable to register the object: %s", e.message);
        }

        return true;
    }

    public static int main (string[] args) {
        return new InstallerDaemon.Application ().run (args);
    }
}
