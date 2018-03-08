# Installer
[![Translation status](https://l10n.elementary.io/widgets/installer/-/svg-badge.svg)](https://l10n.elementary.io/projects/installer/?utm_source=widget)
[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=46189108)](https://www.bountysource.com/trackers/46189108-elementary-pantheon-installer)

> Note: this is the work-in-progress installer and has not been released yet. For the current installer, see [Ubiquity](https://wiki.ubuntu.com/Ubiquity).

An installer for open-source operating systems. See the [wiki](https://github.com/elementary/installer/wiki) for goals, design spec, user flow, and details about each step.

## Building, Testing, and Installation

You'll need the following dependencies:

 - meson
 - desktop-file-utils
 - gettext
 - libgnomekbd-dev
 - libgtk-3-dev
 - libgee-0.8-dev
 - libjson-glib-dev
 - libxml2-dev
 - libxml2-utils
 - [distinst](https://github.com/system76/distinst/)
 - valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja test` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `io.elementary.installer`

    sudo ninja install
    io.elementary.installer
    
You can also use test mode for development to disable some destructive behaviors like restarting and shutting down:

`io.elementary.installer -t` or `io.elementary.installer --test`

