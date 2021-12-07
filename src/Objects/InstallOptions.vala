// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class InstallOptions : GLib.Object {
    private static InstallOptions _options_object;
    private uint64 minimum_size;
    private uint64 layout_hash;
    private bool disks_moved;
    private Distinst.InstallOptions _options;
    private Distinst.Disks disks;
    public Distinst.InstallOption? selected_option;
    public bool is_recovery_mode = false;

    private Gee.ArrayList<string> unlocked_devices { get; set; default = new Gee.ArrayList<string> (); }

    // The amount of free space that should be retained when shrinking (20 GiB).
    public const uint64 SHRINK_OVERHEAD = 20 * 2 * 1024 * 1024;

    public static unowned InstallOptions get_default () {
        if (_options_object == null || _options_object.disks_moved) {
            _options_object = new InstallOptions ();
        }

        return _options_object;
    }

    public void set_minimum_size (uint64 size) {
        minimum_size = size;
    }

    public bool has_recovery () {
        return null != get_options ().get_recovery_option ();
    }

    public bool is_oem_mode () {
        var recovery = get_options ().get_recovery_option ();
        return null != recovery && recovery.get_oem_mode ();
    }

    public bool is_unlocked (string path) {
        foreach (var dev in unlocked_devices) {
            if (dev == path) {
                return true;
            }
        }

        return false;
    }

    public bool contains_luks () {
        return disks.contains_luks ();
    }

    public void decrypt(string device, string pv, string pass) throws GLib.Error {
        try {
            Utils.decrypt_partition (disks, device, pv, pass);
        } catch (Error e) {
            throw e;
        }

        layout_hash = Distinst.device_layout_hash ();

        // Record the name of the device that was unlocked.
        unlocked_devices.add(device);

        // Update the list of available options.
        _options = new Distinst.InstallOptions (disks, minimum_size, SHRINK_OVERHEAD);
        selected_option = null;
    }

    // Get the current set of installation options.
    public unowned Distinst.InstallOptions get_options () {
        if (null == _options) {
            disks = Distinst.Disks.probe ();
            disks.initialize_volume_groups ();
            layout_hash = Distinst.device_layout_hash ();
            _options = new Distinst.InstallOptions (disks, minimum_size, SHRINK_OVERHEAD);
        }

        return _options;
    }

    // Get the current set of installation options, and update the options if disk changes occurred.
    public unowned Distinst.InstallOptions get_updated_options () {
        var new_hash = Distinst.device_layout_hash ();
        if (layout_hash != new_hash) {
            layout_hash = new_hash;
            disks = Distinst.Disks.probe ();
            disks.initialize_volume_groups ();
            _options = new Distinst.InstallOptions (disks, minimum_size, SHRINK_OVERHEAD);
            selected_option = null;

            unlocked_devices.clear ();
        }

        return _options;
    }

    public unowned Distinst.Disks borrow_disks () {
        return disks;
    }

    public void reset () {
        _options = null;
        selected_option = null;
        unlocked_devices.clear();
        this.get_options();
    }

    // Transder ownership of the disks to the caller.
    public Distinst.Disks take_disks () {
        disks_moved = true;
        return (owned) disks;
    }

    public unowned Distinst.InstallOption? get_selected_option () {
        return selected_option;
    }
}
