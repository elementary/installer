public class Username : Gtk.Box {
    public signal void changed ();
    public new signal void activate ();

    private Gtk.Entry realname_entry;
    private Gtk.Entry username_entry;

    construct {
        var realname_label = new Granite.HeaderLabel (_("Full Name"));
        realname_entry = new Gtk.Entry ();
        realname_entry.grab_focus ();
        realname_entry.activate.connect (() => activate());
        realname_entry.changed.connect (() => {
            username_entry.set_text (realname_entry.get_text());
        });

        var username_label = new Granite.HeaderLabel (_("User Name"));
        username_entry = new Gtk.Entry ();
        username_entry.set_max_length (31);
        username_entry.activate.connect(() => activate());
        username_entry.changed.connect (() => {
            username_entry.set_text (validate (username_entry.get_text ()));
            changed ();
        });

        add (realname_label);
        add (realname_entry);
        add (username_label);
        add (username_entry);
        add (new Gtk.Label(_("This will be used to name your home folder.")) {
            margin_top = 4,
            xalign = (float) 0.0
        });
    }

    public string get_real_name () {
        return realname_entry.get_text ();
    }

    public string get_user_name () {
        return username_entry.get_text ();
    }

    public new void grab_focus () {
        realname_entry.grab_focus ();
    }

    public bool is_ready () {
        return realname_entry.get_text_length () != 0
            && username_entry.get_text_length () != 0;
    }

    private string validate (string input) {
        var text = new StringBuilder ();

        int i = 0;
        char c = input[i];
        while (c != '\0') {
            char cl = c.tolower ();
            if (cl.isalnum () || cl == '_') {
                text.append_c (cl);
            }
            i++;
            c = input[i];
        }

        return (owned) text.str;
    }
}
