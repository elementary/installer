void main (string[] args) {
    Test.init (ref args);
    add_hostname_validator_tests ();
    Test.run ();
}
