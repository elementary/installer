project(
    'io.elementary.installer',
    'vala', 'c',
    meson_version : '>= 0.56.0',
    version: '8.1.1'
)

add_global_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"', language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

gnome = import('gnome')
i18n = import('i18n')

glib_dep = dependency('glib-2.0', version: '>=2.74')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk4')
gtk_wayland_dep = dependency('gtk4-wayland')
gtk_x11_dep = dependency('gtk4-x11')
gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-2.0')
granite_dep = dependency('granite-7', version: '>=7.4.0')
adw_dep = dependency('libadwaita-1', version: '>=1.4.0')
json_glib_dep = dependency('json-glib-1.0')
xkbregistry_dep = dependency('xkbregistry')
pwquality_dep = dependency('pwquality')
pantheon_wayland_dep = dependency('pantheon-wayland-1')
systemd_dep = dependency('systemd')
x11_dep = dependency('x11')

installer_backend = get_option('installer_backend')
if installer_backend == 'distinst'
    distinst_dep = dependency('distinst')
else
    error('No supported installer backend provided')
endif

asresources = gnome.compile_resources(
    'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

subdir('po')
subdir('common')
subdir('daemon')
subdir('src')
subdir('session')
subdir('data')
subdir('test')
