/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */


// Validate a hostname according to [IETF RFC 1123](https://tools.ietf.org/html/rfc1123)
void add_hostname_validator_tests () {
    Test.add_func ("/valid", () => {
        assert (Utils.hostname_is_valid ("VaLiD-HoStNaMe"));
        assert (Utils.hostname_is_valid ("50-name"));
        assert (Utils.hostname_is_valid ("235235"));
        assert (Utils.hostname_is_valid ("example.com"));
        assert (Utils.hostname_is_valid ("VaLid.HoStNaMe"));
        assert (Utils.hostname_is_valid ("123.456"));
    });

    Test.add_func ("/invalid", () => {
        // It is not empty
        assert (!Utils.hostname_is_valid (""));

        // It is 253 or fewer characters
        assert (!Utils.hostname_is_valid ("foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo.bar.baz.foo"));

        // It does not contain any characters outside of the alphanumeric range, except for `-` and `.`
        assert (!Utils.hostname_is_valid ("asdf@fasd"));
        assert (!Utils.hostname_is_valid ("@asdfl"));
        assert (!Utils.hostname_is_valid ("asd f@"));

        // It does not start or end with `-` or `.`
        assert (!Utils.hostname_is_valid ("-invalid-name"));
        assert (!Utils.hostname_is_valid ("also-invalid-"));
        assert (!Utils.hostname_is_valid (".invalid"));
        assert (!Utils.hostname_is_valid ("invalid.name."));

        // Its labels (characters separated by `.`) are not empty.
        assert (!Utils.hostname_is_valid ("empty..label"));

        // Its labels do not start or end with '-' or '.'
        assert (!Utils.hostname_is_valid ("invalid.-starting.char"));
        assert (!Utils.hostname_is_valid ("invalid.ending-.char"));

        // Its labels are 63 or fewer characters.
        assert (!Utils.hostname_is_valid ("foo.label-is-way-to-longgggggggggggggggggggggggggggggggggggggggggggg.org"));
    });
}

void main (string[] args) {
    Test.init (ref args);
    add_hostname_validator_tests ();
    Test.run ();
}
