autostartdir = join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
schemadir = join_paths(get_option('datadir'), 'glib-2.0', 'schemas')

i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'desktop',
    install_dir: join_paths(get_option('datadir'), 'applications'),
    install: true
)

i18n.merge_file(
    input: 'installer.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)

install_data(
    'installer.desktop',
    install_dir: join_paths(get_option('datadir'), 'xsessions')
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

install_subdir(
    'gsd',
    install_dir: autostartdir,
    strip_directory: true
)

install_data(
    'installer.session',
    install_dir: join_paths(get_option('datadir'), 'gnome-session', 'sessions')
)

install_data(
    'installer-default-settings.gschema.override',
    install_dir: schemadir
)

# Test the desktop file
validate_desktop_exe = find_program('desktop-file-validate')
test ('Validate desktop file', validate_desktop_exe,
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)

icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps'),
        rename: meson.project_name() + '.svg'
    )
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps'),
        rename: meson.project_name() + '.svg'
    )
endforeach
