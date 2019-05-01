# Installer
[![Translation status](https://l10n.elementary.io/widgets/installer/-/svg-badge.svg)](https://l10n.elementary.io/projects/installer/?utm_source=widget)
[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=46189108)](https://www.bountysource.com/trackers/46189108-elementary-pantheon-installer)

An installer for open-source operating systems. See the [wiki](https://github.com/elementary/installer/wiki) for goals, design spec, user flow, and details about each step.

## Building, Testing, and Installation

You'll need the following dependencies:

 - meson
 - desktop-file-utils
 - gettext
 - gparted
 - libgnomekbd-dev
 - libgranite-dev >= 0.5
 - libgtk-3-dev
 - libgee-0.8-dev
 - libjson-glib-dev
 - libpwquality-dev
 - libxml2-dev
 - libxml2-utils
 - [distinst](https://github.com/pop-os/distinst/)
 - valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja test` to build and run automated tests.

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `io.elementary.installer`. Note that listing drives and actually installing requires root.

    sudo ninja install
    io.elementary.installer

You can also use `--test` mode for development to disable destructive behaviors like installing, restarting, and shutting down:

    io.elementary.installer --test

For debug messages, set the `G_MESSAGES_DEBUG` environment variable, e.g. to `all`:

    G_MESSAGES_DEBUG=all io.elementary.installer

