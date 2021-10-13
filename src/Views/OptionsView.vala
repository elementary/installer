public delegate void ToggleButtonFn (Gtk.ToggleButton button);

public class OptionsView: AbstractInstallerView {
    public Gtk.Box options;
    private Gtk.SizeGroup icon_sg;

    public Gtk.Button next_button;

    public signal void next ();

    public Gtk.Label description;

    public OptionsView (string artwork, string title) {
        Object (
            cancellable: true,
            title: title,
            artwork: title
        );
    }

    construct {
        options = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        options.valign = Gtk.Align.CENTER;
        options.halign = Gtk.Align.CENTER;

        icon_sg = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);

        var scroller = new Gtk.ScrolledWindow (null, null);
        scroller.vexpand = true;
        scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroller.add (options);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

        this.description = new Gtk.Label (null);
        description.hexpand = true;
        description.max_width_chars = 60;
        description.wrap = true;
        description.hide();
        description.no_show_all = true;
        content.add (description);
        content.add (scroller);

        content_area.attach (content, 1, 0, 1, 2);

        next_button = new Gtk.Button ();
        next_button.sensitive = false;
        next_button.can_default = true;
        next_button.clicked.connect (() => next ());

        action_area.add (next_button);
        action_area.homogeneous = true;
    }

    protected void select_first_option () {
        weak Gtk.Widget first_option = options.get_children ().nth_data (0);
        if (first_option != null && first_option is Gtk.ToggleButton) {
            var button = (Gtk.ToggleButton) first_option;
            button.grab_focus ();
            button.clicked ();
        }
    }

    protected void add_option (string image, string message, string? desc, ToggleButtonFn func) {
        var icon = new Gtk.Image.from_icon_name (image, Gtk.IconSize.DIALOG);
        icon.use_fallback = true;
        icon_sg.add_widget (icon);

        var label = new Gtk.Label (message);
        label.halign = Gtk.Align.START;
        label.hexpand = true;
        label.valign = Gtk.Align.END;

        var content = new Gtk.Grid ();
        content.margin = 6;
        content.column_spacing = 6;
        content.row_spacing = 6;
        content.orientation = Gtk.Orientation.VERTICAL;
        content.attach (icon, 0, 0, 1, desc == null ? 1 : 2);
        content.attach (label, 1, 0);

        if (desc != null) {
            var desc_label = new Gtk.Label ("<small>%s</small>".printf (desc));
            desc_label.halign = Gtk.Align.START;
            desc_label.use_markup = true;
            desc_label.valign = Gtk.Align.START;
            desc_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            content.attach (desc_label, 1, 1);
        } else {
            label.valign = Gtk.Align.CENTER;
        }

        var button = new Gtk.ToggleButton ();
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        func (button);
        button.add (content);
        button.show_all ();

        options.add (button);
    }

    protected void clear_options () {
        options.get_children ().foreach ((child) => child.destroy ());
    }

    protected void sort_sensitive () {
        Gtk.Widget[] disabled = {};

        foreach (var child in options.get_children ()) {
            if (!child.sensitive) {
                disabled += child;
            }
        }

        foreach (var child in disabled) {
            options.remove (child);
            options.add (child);
        }
    }
}
