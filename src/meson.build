vala_files = [
    'Application.vala',
    'HostnameValidator.vala',
    'MainWindow.vala',
    'Utils.vala',
    'Helpers/InstallerDaemon.vala',
    'Helpers/LocaleHelper.vala',
    'Helpers/LogHelper.vala',
    'Objects/Configuration.vala',
    'Objects/KeyboardLayout.vala',
    'Objects/KeyboardVariant.vala',
    'Objects/Mount.vala',
    'Views/AbstractInstallerView.vala',
    'Views/CheckView.vala',
    'Views/DiskView.vala',
    'Views/DriversView.vala',
    'Views/EncryptView.vala',
    'Views/ErrorView.vala',
    'Views/KeyboardLayoutView.vala',
    'Views/LanguageView.vala',
    'Views/PartitioningView.vala',
    'Views/ProgressView.vala',
    'Views/TryInstallView.vala',
    'Views/SuccessView.vala',
    'Widgets/DecryptMenu.vala',
    'Widgets/DescriptionRow.vala',
    'Widgets/DiskBar.vala',
    'Widgets/DiskGrid.vala',
    'Widgets/InstallTypeGrid.vala',
    'Widgets/PartitionBlock.vala',
    'Widgets/PartitionMenu.vala',
    'Widgets/Terminal.vala',
    'Widgets/VariantWidget.vala',
    common_files,
]

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())
configuration_data.set('LANG_LIST', get_option('supported_languages'))
configuration_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))

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
    gee_dep,
    glib_dep,
    gobject_dep,
    granite_dep,
    gtk_dep,
    adw_dep,
    json_glib_dep,
    pwquality_dep,
    xkbregistry_dep
]

executable(meson.project_name(), vala_files, config_file,
           asresources,
           dependencies : gui_dependencies,
           install: true)
