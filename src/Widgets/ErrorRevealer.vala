public class ErrorRevealer : Gtk.Revealer {
    public Gtk.Label label_widget;

    public string label {
        set {
            label_widget.label = "<span font_size=\"small\">%s</span>".printf (value);
        }
    }

    public ErrorRevealer (string label) {
        label_widget = new Gtk.Label ("<span font_size=\"small\">%s</span>".printf (label));
        label_widget.halign = Gtk.Align.END;
        label_widget.justify = Gtk.Justification.RIGHT;
        label_widget.max_width_chars = 55;
        label_widget.use_markup = true;
        label_widget.wrap = true;
        label_widget.xalign = 1;

        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        add (label_widget);
    }
}

public class ValidatedEntry : Gtk.Entry {
    public bool is_valid { get; set; default = false; }

    construct {
        activates_default = true;
    }
}