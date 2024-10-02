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
        assert (!Utils.hostname_is_valid ("-invalid-name"));
        assert (!Utils.hostname_is_valid ("also-invalid-"));
        assert (!Utils.hostname_is_valid ("asdf@fasd"));
        assert (!Utils.hostname_is_valid ("@asdfl"));
        assert (!Utils.hostname_is_valid ("asd f@"));
        assert (!Utils.hostname_is_valid (".invalid"));
        assert (!Utils.hostname_is_valid ("invalid.name."));
        assert (!Utils.hostname_is_valid ("foo.label-is-way-to-longgggggggggggggggggggggggggggggggggggggggggggg.org"));
        assert (!Utils.hostname_is_valid ("invalid.-starting.char"));
        assert (!Utils.hostname_is_valid ("invalid.ending-.char"));
        assert (!Utils.hostname_is_valid ("empty..label"));
    });
}
