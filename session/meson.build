autostartdir = get_option('sysconfdir') / 'xdg' / 'autostart'
schemadir = get_option('datadir') / 'glib-2.0' / 'schemas'

gsd_components = [
    'org.gnome.SettingsDaemon.MediaKeys',
    'org.gnome.SettingsDaemon.Power',
    'org.gnome.SettingsDaemon.XSettings',
]

install_data(
    'autostart.desktop',
    install_dir: autostartdir,
    rename: meson.project_name() + '.desktop'
)

install_data(
    'compositor-autostart.desktop',
    install_dir: autostartdir,
    rename: meson.project_name() + '.compositor.desktop'
)

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

systemd_userunitdir = get_option('systemduserunitdir')
if systemd_userunitdir == ''
    systemd_userunitdir = systemd_dep.get_pkgconfig_variable('systemduserunitdir', define_variable: ['prefix', get_option('prefix')])
endif

desktop_plain = 'installer'

shell_component = {
    desktop_plain: 'io.elementary.installer.compositor',
}

required_components = {
    desktop_plain: gsd_components,
}

gnome_session_wanted_targets = []
foreach component: required_components[desktop_plain]
    gnome_session_wanted_targets += 'Wants=@0@.target'.format(component)
endforeach

session_config = configure_file(
    input: 'session.conf.in',
    output: 'session.conf',
    configuration: {
        'requires_component': shell_component[desktop_plain],
        'wants_required_components': '\n'.join(gnome_session_wanted_targets),
    },
    install_dir: systemd_userunitdir / 'gnome-session@installer.target.d',
)
