# Installer
[![Translation status](https://l10n.elementary.io/widgets/installer/-/svg-badge.svg)](https://l10n.elementary.io/projects/installer/?utm_source=widget)
[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=46189108)](https://www.bountysource.com/trackers/46189108-elementary-pantheon-installer)

> Note: this is the work-in-progress installer and has not been released yet. For the current installer, see [Ubiquity](https://wiki.ubuntu.com/Ubiquity).

The installer for open-source operating systems. The installation experience should be attractive and effortless to reassure new users that their new OS is the right choice. The process should feel safe and should only highlight risk when necessary (e.g. when data will be destroyed). This installer intends to cater to:
- New users with no understanding of the nature of an operating system.
- Average users who want to perform typical installations like dual-boot in a hands-off manner.
- Expert users who have very specific configuration requirements.
- OEM-like users who are performing the OS installation, but leaving user-specific details for the final end user.

For the sake of providing a single installer experience, we assume that every install is an OEM install. What that means is that additional setup (like creating users) will happen after the first boot into the clean system and not in the installer.

[Read The Full Specification on Google Docs](https://docs.google.com/document/d/1Sw07eNjORV1rBEGhlWJmD39BgNBVNbJEJhLzrc_6T0w/edit)

## Building, Testing, and Installation

You'll need the following dependencies:

 - meson
 - desktop-file-utils
 - gettext
 - libgnomekbd-dev
 - libgtk-3-dev
 - libjson-glib-dev
 - libxml2-dev
 - libxml2-utils
 - [distinst](https://github.com/system76/distinst/)
 - valac

Run `meson build` to configure the build environment, change to the build directory, and run `ninja test` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `io.elementary.installer`

    sudo ninja install
    io.elementary.installer
