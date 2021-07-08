vala_files = [
    'Application.vala',
    'MainWindow.vala',
    'Utils.vala',
    'Helpers/Inhibitor.vala',
    'Helpers/InstallerDaemon.vala',
    'Helpers/KeyboardLayoutHelper.vala',
    'Helpers/LocaleHelper.vala',
    'Helpers/LogHelper.vala',
    'Objects/Configuration.vala',
    'Objects/Mount.vala',
    'Views/AbstractInstallerView.vala',
    'Views/AutomatedView.vala',
    'Views/CheckView.vala',
    'Views/DiskView.vala',
    'Views/EncryptView.vala',
    'Views/ErrorView.vala',
    'Views/KeyboardLayoutView.vala',
    'Views/LanguageView.vala',
    'Views/PartitioningView.vala',
    'Views/ProgressView.vala',
    'Views/TryInstallView.vala',
    'Views/SuccessView.vala',
    'Widgets/DecryptMenu.vala',
    'Widgets/DiskBar.vala',
    'Widgets/DiskGrid.vala',
    'Widgets/InstallTypeGrid.vala',
    'Widgets/LayoutWidget.vala',
    'Widgets/PartitionBar.vala',
    'Widgets/PartitionMenu.vala',
    'Widgets/Terminal.vala',
    'Widgets/VariantWidget.vala',
    common_files,
]

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())
configuration_data.set('LANG_LIST', get_option('supported_languages'))

xkbconf = dependency('xkeyboard-config')
xkb_base = xkbconf.get_pkgconfig_variable('xkb_base')
configuration_data.set('XKB_BASE', xkb_base)

isocodes = dependency('iso-codes')
isocodes_prefix = isocodes.get_pkgconfig_variable('prefix')
isocodes_location = join_paths(isocodes_prefix, get_option('datadir'), 'iso-codes', 'json')
configuration_data.set('ISO_CODES_LOCATION', isocodes_location)

configuration_data.set('PREFERRED_LANG_LIST', get_option('preferred_languages'))

config_file = configure_file(
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: configuration_data
)

gui_dependencies = [
    distinst_dep,
    gee_dep,
    glib_dep,
    gnome_keyboard_dep,
    gnome_keyboard_ui_dep,
    gobject_dep,
    granite_dep,
    gtk_dep,
    handy_dep,
    json_glib_dep,
    pwquality_dep,
    xml2_dep
]

executable(meson.project_name(), vala_files, config_file,
           asresources,
           dependencies : gui_dependencies,
           install: true)
