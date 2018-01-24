
vala_files = [
    'Application.vala',
    'MainWindow.vala',
    'Utils.vala',
    'Helpers/KeyboardLayoutHelper.vala',
    'Helpers/LocaleHelper.vala',
    'Helpers/LogHelper.vala',
    'Dialogs/EndSessionDialog.vala',
    'Objects/org.freedesktop.udisks2.vala',
    'Objects/Configuration.vala',
    'Objects/Disk.vala',
    'Objects/Partition.vala',
    'Objects/PartitionTable.vala',
    'Views/AbstractInstallerView.vala',
    'Views/CheckView.vala',
    'Views/DiskView.vala',
    'Views/EncryptView.vala',
    'Views/ErrorView.vala',
    'Views/KeyboardLayoutView.vala',
    'Views/LanguageView.vala',
    'Views/ProgressView.vala',
    'Views/TryInstallView.vala',
    'Views/SuccessView.vala',
    'Widgets/DiskGrid.vala',
    'Widgets/LayoutWidget.vala',
    'Widgets/VariantWidget.vala'
]

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())
configuration_data.set('LANG_LIST', get_option('supported_languages'))
configuration_data.set('PREFERRED_LANG_LIST', get_option('preferred_languages'))
configuration_data.set('SQUASHFS_PATH', get_option('squashfs_path'))

config_file = configure_file(
    input: 'Config.vala.in',
    output: 'Config.vala',
    configuration: configuration_data
)

executable(meson.project_name(), vala_files, config_file,
           asresources,
           dependencies : dependencies,
           install: true)
