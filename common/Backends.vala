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
                return "Classic Installation Mode (BOO!)";
            case REPART:
                return "Modern Installation Mode (YOLO!)";
            case UNKNOWN:
            default:
                return "Unknown Installation Mode (OUCH!)";
        }
    }

    public string get_description () {
        switch (this) {
            case DISTINST:
                return "This is the classic (old and unloved) installation mode. You would be ill-advised to choose this.";
            case REPART:
                return "This is the modern (new fangled) installation mode. Here be dragons, you have been warned.";
            case UNKNOWN:
            default:
                return "This is an unknown installation mode. WTF is going on here?!";
        }
    }
}

public static InstallerDaemon.Backend[] get_backends () {
    return { InstallerDaemon.Backend.DISTINST, InstallerDaemon.Backend.REPART };
}
