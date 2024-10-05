autostartdir = get_option('sysconfdir') / 'xdg' / 'autostart'
desktop_file_install = find_program('desktop-file-install')
schemadir = get_option('datadir') / 'glib-2.0' / 'schemas'

gsd_components = [
    'org.gnome.SettingsDaemon.A11ySettings',
    'org.gnome.SettingsDaemon.Color',
    'org.gnome.SettingsDaemon.Keyboard',
    'org.gnome.SettingsDaemon.MediaKeys',
    'org.gnome.SettingsDaemon.Power',
    'org.gnome.SettingsDaemon.Rfkill',
    'org.gnome.SettingsDaemon.ScreensaverProxy',
    'org.gnome.SettingsDaemon.Sound',
    'org.gnome.SettingsDaemon.XSettings',
]

session_components = [
  'io.elementary.installer.compositor',
  gsd_components,
  'io.elementary.installer'
]

session_configuration = configuration_data()
session_configuration.set('SESSION_COMPONENTS', ';'.join(session_components))

configure_file(
    input: 'installer.session.in',
    output: '@BASENAME@',
    configuration: session_configuration,
    install_dir: get_option('datadir') / 'gnome-session' / 'sessions'
)

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
    'installer-default-settings.gschema.override',
    install_dir: schemadir
)

foreach component : gsd_components
    original_filename = component + '.desktop'
    original_autostart_file = autostartdir / original_filename

    patched_filename = 'pantheon-' + component + '.desktop'

    custom_target('create-gsd-autostart' + patched_filename,
        input: original_autostart_file,
        output: patched_filename,
        command: [
            desktop_file_install,
            '--set-key=OnlyShowIn',
            '--set-value=X-Installer',
            '--vendor=pantheon',
            '--dir=@OUTDIR@',
            '@INPUT@',
        ],
        install: true,
        install_dir: autostartdir,
    )
endforeach
