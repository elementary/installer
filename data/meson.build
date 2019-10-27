i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    type: 'desktop',
    install_dir: join_paths(get_option('datadir'), 'applications'),
    install: true
)

install_data(
    'installer.desktop',
    install_dir: join_paths(get_option('datadir'), 'xsessions')
)

install_data(
    'wingpanel-installer.desktop',
    install_dir: join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
)

install_data(
    'installer.session',
    install_dir: join_paths(get_option('datadir'), 'gnome-session', 'sessions')
)

# Test the desktop file
validate_desktop_exe = find_program('desktop-file-validate')
test ('Validate desktop file', validate_desktop_exe,
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)
