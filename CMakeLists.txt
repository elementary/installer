project (pantheon-installer)

cmake_minimum_required (VERSION 2.8)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set (DATADIR ${CMAKE_INSTALL_PREFIX}/share)
set (PKGDATADIR "${DATADIR}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME ${CMAKE_PROJECT_NAME})

# CTest
include (CTest)
if (BUILD_TESTING)
    add_test (NAME validate-desktop-file COMMAND desktop-file-validate ${CMAKE_BINARY_DIR}/data/io.elementary.installer.desktop)    
endif ()

# We won't show the languages that aren't available for the installer
file (GLOB languages_list
    "po/*.po"
)

set (LANG_LIST "")
foreach (lang_file ${languages_list})
    get_filename_component(LANG ${lang_file} NAME_WE)
    if (LANG_LIST STREQUAL "")
        set (LANG_LIST ${LANG})
    else ()
        set (LANG_LIST "${LANG_LIST};${LANG}")
    endif ()
endforeach()

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_definitions (-w)

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED
    gtk+-3.0
    granite
    libxml-2.0
)
add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES} m)
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.26" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/Application.vala
    src/MainWindow.vala
    src/LanguageView.vala
    src/CheckView.vala
    src/DiskView/DiskView.vala
    src/DiskView/DiskGrid.vala
    src/DiskView/org.freedesktop.udisks2.vala
PACKAGES
    gtk+-3.0>=3.12
    granite
    libxml-2.0
    posix
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
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
