/*
 * Copyright 2018-2022 System76 <info@system76.com>
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: MIT
 */

namespace Utils {
    private bool hostname_is_valid_char (char c) {
        return (c.isalnum () ||
                c == '-' ||
                c == '.');
    }

    // Based on https://github.com/pop-os/hostname-validator/blob/458fa5a1df98cb663f0456dffb542e1a907861c9/src/lib.rs#L29
    /// Validate a hostname according to [IETF RFC 1123](https://tools.ietf.org/html/rfc1123).
    ///
    /// A hostname is valid if the following condition are true:
    ///
    /// - It does not start or end with `-` or `.`.
    /// - It does not contain any characters outside of the alphanumeric range, except for `-` and `.`.
    /// - It is not empty.
    /// - It is 253 or fewer characters.
    /// - Its labels (characters separated by `.`) are not empty.
    /// - Its labels are 63 or fewer characters.
    /// - Its labels do not start or end with '-' or '.'.
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
