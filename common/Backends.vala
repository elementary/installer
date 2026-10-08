/*
 * Copyright 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public enum InstallerDaemon.Backend {
    DISTINST,
    REPART,
    UNKNOWN;

    public string to_string () {
        switch (this) {
            case DISTINST:
                return "Classic";
            case REPART:
                return "Modern";
            case UNKNOWN:
            default:
                return "Unknown";
        }
    }

    public string get_title () {
        switch (this) {
            case DISTINST:
                return "Classic Installation Mode";
            case REPART:
                return "Modern Installation Mode";
            case UNKNOWN:
            default:
                return "Unknown Installation Mode";
        }
    }

    public string get_description () {
        switch (this) {
            case DISTINST:
                return "This is the classic installation mode.";
            case REPART:
                return "This is the modern installation mode.";
            case UNKNOWN:
            default:
                return "This is an unknown installation mode.";
        }
    }
}

public static InstallerDaemon.Backend[] get_backends () {
    return { InstallerDaemon.Backend.REPART, InstallerDaemon.Backend.DISTINST };
}
