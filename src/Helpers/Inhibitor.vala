/*-
 * Copyright (c) 2016 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[DBus (name = "org.freedesktop.ScreenSaver")]
public interface ScreenSaverIface : Object {
    public abstract uint32 inhibit (string app_name, string reason) throws Error;
    public abstract void un_inhibit (uint32 cookie) throws Error;
    public abstract void simulate_user_activity () throws Error;
}

public class Inhibitor : Object {
    private const string IFACE = "org.freedesktop.ScreenSaver";
    private const string IFACE_PATH = "/ScreenSaver";

    private static Inhibitor? instance = null;

    private uint32? inhibit_cookie = null;

    private ScreenSaverIface? screensaver_iface = null;

    private bool inhibited = false;
    private bool simulator_started = false;

    private Inhibitor () {
        try {
            screensaver_iface = Bus.get_proxy_sync (BusType.SESSION, IFACE, IFACE_PATH, DBusProxyFlags.NONE);
        } catch (Error e) {
            warning ("Could not start screensaver interface: %s", e.message);
        }
    }

    public static Inhibitor get_instance () {
        if (instance == null) {
            instance = new Inhibitor ();
        }

        return instance;
    }

    public void inhibit () {
        if (screensaver_iface != null && !inhibited) {
            try {
                inhibited = true;
                inhibit_cookie = screensaver_iface.inhibit ("Installer", "Installing");
                simulate_activity ();
                debug ("Inhibiting screen");
            } catch (Error e) {
                warning ("Could not inhibit screen: %s", e.message);
            }
        }
    }

    public void uninhibit () {
        if (screensaver_iface != null && inhibited) {//&& inhibit_cookie != null) {
            try {
                inhibited = false;
                screensaver_iface.un_inhibit (inhibit_cookie);
                debug ("Uninhibiting screen");
            } catch (Error e) {
                warning ("Could not uninhibit screen: %s", e.message);
            }
        }
    }

   /*
    * Inhibit currently does not block a suspend from ocurring,
    * so we simulate user activity every 2 mins to prevent it
    */
    private void simulate_activity () {
        if (simulator_started) return;

        simulator_started = true;
        Timeout.add_full (Priority.DEFAULT, 120000, ()=> {
            if (inhibited) {
                try {
                    debug ("Simulating activity");
                    screensaver_iface.simulate_user_activity ();
                } catch (Error e) {
                    warning ("Could not simulate user activity: %s", e.message);
                }
            } else {
                simulator_started = false;
            }

            return inhibited;
        });
    }
}
