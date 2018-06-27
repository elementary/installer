public class Terminal : GLib.Object {
    private Gtk.TextView view;
    public Gtk.TextBuffer buffer { get; construct; }
    public Gtk.ScrolledWindow container;
    public Gtk.ToggleButton toggle;

    private double prev_upper_adj = 0;

    public string log {
        owned get {
            return view.buffer.text;
        }
    }

    public signal void toggled (bool active);

    public Terminal (Gtk.TextBuffer buffer) {
        Object ( buffer: buffer );
    }

    construct {
        view = new Gtk.TextView.with_buffer (buffer);
        view.editable = false;
        view.cursor_visible = true;
        view.monospace = true;
        view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        view.expand = true;

        // A workaround for https://gitlab.gnome.org/GNOME/gtk/issues/628
        var workaround_box = new Gtk.Grid ();
        workaround_box.margin = 12;
        workaround_box.expand = true;
        workaround_box.add (view);

        container = new Gtk.ScrolledWindow (null, null);
        container.hscrollbar_policy = Gtk.PolicyType.NEVER;
        container.expand = true;
        container.add (workaround_box);
        container.get_style_context ().add_class ("terminal");

        toggle = new Gtk.ToggleButton ();
        toggle.halign = Gtk.Align.END;
        toggle.image = new Gtk.Image.from_icon_name ("utilities-terminal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        toggle.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        toggle.toggled.connect (() => {
            if (toggle.active) {
                scroll_to_bottom ();
            }

            toggled (toggle.active);
        });

        view.size_allocate.connect (() => attempt_scroll ());
    }

    private void attempt_scroll () {
        var adj = container.vadjustment;

        var units_from_end = prev_upper_adj - adj.page_size - adj.value;
        var view_size_difference = adj.upper - prev_upper_adj;
        if (view_size_difference < 0) {
            view_size_difference = 0;
        }

        if (prev_upper_adj <= adj.page_size || units_from_end <= 50) {
            scroll_to_bottom ();
        }

        prev_upper_adj = adj.upper;
    }

    private void scroll_to_bottom () {
        var adj = container.vadjustment;
        adj.value = adj.upper;
    }
}
