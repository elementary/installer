// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright 2024 elementary, Inc. (https://elementary.io)
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
 * Authored by: Marius Meisenzahl <mariusmeisenzahl@gmail.com>
 */

namespace Utils {
    private bool hostname_is_valid_char (char c) {
        return ((c >= 'a' && c <= 'z') ||
                (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') ||
                c == '-' ||
                c == '.');
    }

    // Based on https://github.com/pop-os/hostname-validator/blob/458fa5a1df98cb663f0456dffb542e1a907861c9/src/lib.rs#L29
    public bool hostname_is_valid (string hostname) {
        for (int i = 0; i < hostname.char_count (); i++) {
            char c = hostname[i];
            if (!hostname_is_valid_char (c)) {
                return false;
            }
        }

        string[] labels = hostname.split (".", -1);
        foreach (string label in labels) {
            if (label.char_count () == 0 || label.length > 63 || label[0] == '-' || label[label.length - 1] == '-') {
                return false;
            }
        }

        return !(hostname.char_count () == 0 || hostname.length > 253);
    }
}
