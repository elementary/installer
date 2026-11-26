/*
 * Copyright 2021-2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace InstallerDaemon.Application {
    // We have to do it step by step because the vala compiler has overflows with big numbers.
    public const uint64 ONE_GB = 1000 * 1000 * 1000;
}

private static GLib.MainLoop loop;

private void on_bus_acquired (GLib.DBusConnection connection, string name) {
    try {
        connection.register_object ("/io/elementary/InstallerDaemon", InstallerDaemon.Backend.get_backend ());
    } catch (GLib.Error e) {
        critical ("Unable to register the object: %s", e.message);
    }
}

public static int main (string[] args) {
    loop = new GLib.MainLoop (null, false);

    var owner_id = GLib.Bus.own_name (
        GLib.BusType.SYSTEM,
        "io.elementary.InstallerDaemon",
        GLib.BusNameOwnerFlags.NONE,
        on_bus_acquired,
        () => { },
        () => { loop.quit (); }
    );

    loop.run ();

    GLib.Bus.unown_name (owner_id);

    return 0;
}
