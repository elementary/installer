/*
 * Copyright 2018-2022 System76 <info@system76.com>
 * Copyright 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: MIT
 */

/**
 * Validate a hostname according to [IETF RFC 1123](https://tools.ietf.org/html/rfc1123)
 *
 * Based on https://github.com/pop-os/hostname-validator/blob/458fa5a1df98cb663f0456dffb542e1a907861c9/src/lib.rs#L29
 */

namespace Utils {
    public bool hostname_is_valid (string hostname) {
        // It is not empty
        if (hostname.char_count () == 0) {
            return false;
        }

        // It is 253 or fewer characters
        if (hostname.length > 253) {
            return false;
        }

        // It does not contain any characters outside of the alphanumeric range, except for `-` and `.`
        for (int i = 0; i < hostname.char_count (); i++) {
            char c = hostname[i];
            if (!(c.isalnum () || c == '-' || c == '.')) {
                return false;
            }
        }

        string[] labels = hostname.split (".", -1);
        foreach (string label in labels) {
            // Its labels (characters separated by `.`) are not empty.
            if (label.char_count () == 0) {
                return false;
            }

            // Its labels do not start or end with '-' or '.'
            if (label.has_prefix ("-") || label.has_suffix ("-") || label.has_prefix (".") || label.has_suffix (".")) {
                return false;
            }

            // Its labels are 63 or fewer characters.
            if (label.length > 63) {
                return false;
            }
        }

        return true;
    }
}
