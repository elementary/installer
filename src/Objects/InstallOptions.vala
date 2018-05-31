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
    private Distinst.InstallOptions _options;
    private Distinst.Disks disks;
    public Distinst.InstallOption? selected_option;

    public static unowned InstallOptions get_default () {
        if (_options_object == null) {
            _options_object = new InstallOptions ();
        }

        return _options_object;
    }

    public void set_minimum_size (uint64 size) {
        minimum_size = size;
    }

    public bool has_recovery () {
        return null != get_options().get_recovery_option ();
    }

    public bool is_oem_mode () {
        var recovery = get_options().get_recovery_option ();
        return null != recovery && recovery.get_oem_mode ();
    }

    public unowned Distinst.InstallOptions get_options () {
        if (null == _options) {
            disks = Distinst.Disks.probe ();
            disks.initialize_volume_groups ();
            layout_hash = Distinst.device_layout_hash ();
            _options = new Distinst.InstallOptions (disks, minimum_size);
        }

        return _options;
    }

    // Returns an updated option if the device layout has changed.
    public unowned Distinst.InstallOptions get_updated_options () {
        var new_hash = Distinst.device_layout_hash ();
        if (layout_hash != new_hash) {
            layout_hash = new_hash;
            disks = Distinst.Disks.probe ();
            _options = new Distinst.InstallOptions (disks, minimum_size);
            selected_option = null;
        }

        return _options;
    }

    public Distinst.Disks get_disks () {
        var moved = (owned) disks;
        _options = null;
        selected_option = null;
        return moved;
    }

    public unowned Distinst.InstallOption? get_selected_option () {
        return selected_option;
    }
}
