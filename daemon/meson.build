vala_files = [
    'Daemon.vala',
    'DistinstBackend.vala',
    'RepartBackend.vala',
    common_files
]

daemon_dependencies = [
    gee_dep,
    glib_dep,
    gio_dep,
    gobject_dep,
    distinst_dep,
    meson.get_compiler('vala').find_library('posix')
]

systemdunitdir = systemd_dep.get_pkgconfig_variable('systemdsystemunitdir')

install_data(
    'io.elementary.InstallerDaemon.service',
    install_dir: systemdunitdir
)

install_data('io.elementary.InstallerDaemon.conf', install_dir : get_option('datadir') / 'dbus-1' / 'system.d')

executable(meson.project_name() + '-daemon', vala_files,
           dependencies : daemon_dependencies,
           install: true)
