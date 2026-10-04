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
}

public static InstallerDaemon.Backend[] get_backends () {
    return { InstallerDaemon.Backend.DISTINST, InstallerDaemon.Backend.REPART };
}
