class IconChooser: Gtk.DrawingArea {
    private Gdk.Pixbuf pixbuf;

    public string icon_path { get; set; }

    public IconChooser(string icon_path) {
        Object ( icon_path: icon_path );
        this.load_icon(icon_path);
    }

    construct {
        this.set_size_request(128, 128);
        this.draw.connect((widget, cr) => {
            int width = this.pixbuf.get_width ();
            int height = this.pixbuf.get_height ();
            cr.arc(64.0, 64.0, 60, 0, 2*Math.PI);
            cr.clip();
            cr.scale(128.0 / (double) width, 128.0 / (double) height);
            Gdk.cairo_set_source_pixbuf(cr, this.pixbuf, 1, 1);
            cr.paint();

            if (Gtk.StateFlags.PRELIGHT in this.get_state_flags()) {
                cr.set_operator(Cairo.Operator.LIGHTEN);
                cr.set_source_rgba (1, 1, 1, 0.5);
                cr.rectangle (0, 0, 128, 128);
                cr.fill();
            }

            return false;
        });

        var flags = Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK;

        this.add_events(flags);

        this.button_press_event.connect(() => {
            this.icon_dialog();
            return false;
        });

        this.enter_notify_event.connect(() => {
            this.set_state_flags(Gtk.StateFlags.PRELIGHT, false);
            this.queue_draw();
        });

        this.leave_notify_event.connect(() => {
            this.unset_state_flags(Gtk.StateFlags.PRELIGHT);
            this.queue_draw();
        });
    }

    void load_icon(string path) {
        try {
            this.pixbuf = new Gdk.Pixbuf.from_file(path)
                .scale_simple(128, 128, Gdk.InterpType.HYPER);

            this.icon_path = path;
        } catch (Error error) {
            warning("Failed to set icon to %s: %s", path, error.message);
        }
    }

    void icon_dialog() {
        var filter = new Gtk.FileFilter();
        filter.add_pattern("*.[Jj][Pp][Gg]");
        filter.add_pattern("*.[Jj][Pp][Ee][Gg]");
        filter.add_pattern("*.[Pp][Nn][Gg");

        var preview_image = new Gtk.Image ();

        var dialog = new Gtk.FileChooserNative(
            "Choose Icon",
            new Gtk.Window(Gtk.WindowType.POPUP),
            Gtk.FileChooserAction.OPEN,
            _("_Open"),
            _("_Cancel")
        );

        dialog.set_filter(filter);
        dialog.set_current_folder("/usr/share/pixmaps/faces");
        dialog.set_preview_widget(preview_image);

        dialog.update_preview.connect(() => {
            try {
                var pixbuf = new Gdk.Pixbuf.from_file(dialog.get_filename());
                int width = pixbuf.get_width();
                int height = pixbuf.get_height();
                double scale = double.min(256.0 / (double) width, 256.0 / (double) height);
                width = (int) (scale * width);
                height = (int) (scale * height);
                pixbuf = pixbuf.scale_simple(width, height, Gdk.InterpType.HYPER);
                preview_image.set_from_pixbuf(pixbuf);
                dialog.set_preview_widget_active(true);

            } catch (Error error) {
                dialog.set_preview_widget_active(false);
            }
        });

        if (Gtk.ResponseType.ACCEPT == dialog.run()) {
            this.load_icon(dialog.get_filename());
        }
    }
}