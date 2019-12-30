namespace Modes {
    public enum Mode {
        INSTALL,
        REFRESH
    }

    public Mode mode (Distinst.RecoveryOption? recovery_option) {
        if (recovery_option == null) {
            return Mode.INSTALL;
        }

        unowned uint8[] mode_ref = recovery_option.mode ();

        return (mode_ref != null && Utils.string_from_utf8 (mode_ref) == "refresh")
            ? Mode.REFRESH
            : Mode.INSTALL;
    }
}
