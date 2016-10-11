configure_file_translation (${CMAKE_CURRENT_SOURCE_DIR}/io.elementary.installer.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.installer.desktop ${CMAKE_SOURCE_DIR}/po/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.installer.desktop DESTINATION share/applications)
