project(
    'io.elementary.installer',
    'vala', 'c',
    meson_version : '>= 0.56.0',
    version: '8.0.0',
    default_options: 'sysconfdir=/etc'
)

add_global_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"', language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

gnome = import('gnome')
i18n = import('i18n')

distinst_dep = dependency('distinst')
glib_dep = dependency('glib-2.0', version: '>=2.74')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk4')
gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-2.0')
granite_dep = dependency('granite-7', version: '>=7.4.0')
gsd_dep = dependency('gnome-settings-daemon', version: '>= 3.36.0')
adw_dep = dependency('libadwaita-1', version: '>=1.4.0')
json_glib_dep = dependency('json-glib-1.0')
xml2_dep = dependency('libxml-2.0')
pwquality_dep = dependency('pwquality')
systemd_dep = dependency('systemd')

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
