vala_files = [
    'Daemon.vala',
    common_files
]

daemon_dependencies = [
    gee_dep,
    glib_dep,
    gio_dep,
    gobject_dep,
]

args = ''

if installer_backend == 'distinst'
    vala_files += ['DistinstBackend.vala']
    daemon_dependencies += [distinst_dep]
    args += '--define=DISTINST_BACKEND'
else
    error('No supported installer backend provided')
endif

systemdunitdir = systemd_dep.get_pkgconfig_variable('systemdsystemunitdir')

install_data(
    'io.elementary.InstallerDaemon.service',
    install_dir: systemdunitdir
)

install_data('io.elementary.InstallerDaemon.conf', install_dir : get_option('datadir') / 'dbus-1' / 'system.d')

executable(meson.project_name() + '-daemon', vala_files,
           dependencies : daemon_dependencies,
           vala_args : args,
           install: true)
