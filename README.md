# Pantheon Installer

[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=46189108)](https://www.bountysource.com/trackers/46189108-elementary-pantheon-installer)

The installer for elementary OS. The installation experience should be attractive and effortless to reassure new users that elementary OS is the right choice. The process should feel safe and should only highlight risk when necessary (e.g. when data will be destroyed). This installer intends to cater to:
- New users with no understanding of the nature of an operating system.
- Average users who want to perform typical installations like dual-boot in a hands-off manner.
- Expert users who have very specific configuration requirements.
- OEM-like users who are performing the OS installation, but leaving user-specific details for the final end user.

For the sake of providing a single installer experience, we assume that every install is an OEM install. What that means is that additional setup (like creating users) will happen after the first boot into the clean system and not in the installer.

[Read The Full Specification For More Info](https://docs.google.com/document/d/1Sw07eNjORV1rBEGhlWJmD39BgNBVNbJEJhLzrc_6T0w/edit)

## Building, Testing, and Installation

You'll need the following dependencies:

 - cmake
 - desktop-file-utils
 - intltool
 - libgranite-dev
 - libgtk-3-dev
 - libxml2-dev
 - libxml2-utils
 - valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make all test` to build and run automated tests

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make all test
    
To install, use `make install`, then execute with `pantheon-installer`

    sudo make install
    pantheon-installer
