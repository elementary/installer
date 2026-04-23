autostartdir = get_option('sysconfdir') / 'xdg' / 'autostart'
schemadir = get_option('datadir') / 'glib-2.0' / 'schemas'

install_data(
    'installer.desktop',
    install_dir: get_option('datadir') / 'xsessions'
)

install_data(
    'installer.session',
    install_dir: get_option('datadir') / 'gnome-session' / 'sessions'
)

install_data(
    'installer-default-settings.gschema.override',
    install_dir: schemadir
)

install_subdir(
    'gsd',
    install_dir: autostartdir,
    strip_directory: true
)

prefix = get_option('prefix')

systemd_userunitdir = systemd_dep.get_pkgconfig_variable('systemduserunitdir')

service_config = configuration_data()
service_config.set('bindir', prefix / get_option('bindir'))

configure_file(
    input: 'compositor.service.in',
    output: 'io.elementary.installer.compositor.service',
    install: true,
    install_dir: systemd_userunitdir,
    configuration: service_config
)

install_data(
    'installer.target',
    rename: 'io.elementary.installer.target',
    install_dir: systemd_userunitdir
)

configure_file(
    input: 'installer.service.in',
    output: 'io.elementary.installer.service',
    configuration: service_config,
    install: true,
    install_dir: systemd_userunitdir
)
