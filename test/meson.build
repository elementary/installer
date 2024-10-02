test_dependencies = [
    glib_dep,
]

tests = executable(
    meson.project_name() + '-tests',
    'HostnameValidatorTest.vala',
    'Test.vala',
    meson.project_source_root() + '/src/HostnameValidator.vala',
    dependencies: test_dependencies
)

test('Test', tests)
