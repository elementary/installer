project (io.elementary.installer)

cmake_minimum_required (VERSION 2.8)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (DATADIR ${CMAKE_INSTALL_PREFIX}/share)
set (PKGDATADIR "${DATADIR}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME ${CMAKE_PROJECT_NAME})
set (VERSION 1.0)

# CTest
include (CTest)
if (BUILD_TESTING)
    add_test (NAME validate-desktop-file COMMAND desktop-file-validate ${CMAKE_BINARY_DIR}/data/${CMAKE_PROJECT_NAME}.desktop)
endif ()

# We won't show the languages that aren't available for the installer
file (GLOB languages_list
    "po/*.po"
)

set (LANG_LIST "en;en_US")
foreach (lang_file ${languages_list})
    get_filename_component(LANG ${lang_file} NAME_WE)
    set (LANG_LIST "${LANG_LIST};${LANG}")
endforeach()

# This list is prioritized, do not sort it alphabetically
set (PREFERRED_LANG_LIST "en;zh;es;fr;pt;ru;de")

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_definitions (-w)

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED
    distinst
    gtk+-3.0
    granite
    json-glib-1.0
    libxml-2.0
    libgnomekbd
    libgnomekbdui
)
add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES} m)
link_directories(${DEPS_LIBRARY_DIRS})

pkg_check_modules(GTK_3_22 QUIET
    gtk+-3.0>=3.22
)

if (GTK_3_22_FOUND)
    set (GTK_3_22_VALA_FLAGS
        -D GTK_3_22
    )
else ()
    set (GTK_3_22_VALA_FLAGS "")
endif ()

# make sure we have vala
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.26" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/Application.vala
    src/MainWindow.vala
    src/Utils.vala
    src/Helpers/KeyboardLayoutHelper.vala
    src/Helpers/LocaleHelper.vala
    src/Dialogs/EndSessionDialog.vala
    src/Objects/org.freedesktop.udisks2.vala
    src/Objects/Configuration.vala
    src/Objects/Disk.vala
    src/Objects/Partition.vala
    src/Objects/PartitionTable.vala
    src/Views/AbstractInstallerView.vala
    src/Views/CheckView.vala
    src/Views/DiskView.vala
    src/Views/ErrorView.vala
    src/Views/KeyboardLayoutView.vala
    src/Views/LanguageView.vala
    src/Views/ProgressView.vala
    src/Views/TryInstallView.vala
    src/Views/SuccessView.vala
    src/Widgets/DiskGrid.vala
    src/Widgets/LayoutWidget.vala
    src/Widgets/VariantWidget.vala
PACKAGES
    distinst
    gtk+-3.0>=3.12
    granite
    json-glib-1.0
    libxml-2.0
    libgnomekbd
    posix
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
    ${GTK_3_22_VALA_FLAGS}
CUSTOM_VAPIS
    ${CMAKE_SOURCE_DIR}/vapi/config.vapi
)

include (GResource)
glib_compile_resources (GLIB_RESOURCES_OS_ICONS data/os-icons/os-icons.gresource.xml)

add_subdirectory (po)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C} ${GLIB_RESOURCES_OS_ICONS})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

add_subdirectory (data)
