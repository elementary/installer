project(
    'io.elementary.installer',
    'vala', 'c',
    version: '1.0.6'
)

add_global_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"', language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

gnome = import('gnome')
i18n = import('i18n')

distinst_dep = dependency('distinst')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk+-3.0')
gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-2.0')
granite_dep = dependency('granite', version: '>=0.5')
handy_dep = dependency('libhandy-1', version: '>=0.90.0')
json_glib_dep = dependency('json-glib-1.0')
xml2_dep = dependency('libxml-2.0')
gnome_keyboard_dep = dependency('libgnomekbd')
gnome_keyboard_ui_dep = meson.get_compiler('c').find_library('gnomekbdui')
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
subdir('data')
