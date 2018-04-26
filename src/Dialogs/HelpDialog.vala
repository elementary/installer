// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Cassidy James Blaede <c@ssidyjam.es>
 *
 */

public class HelpDialog : Gtk.Window {
    private string os = Utils.get_pretty_name ();

    public HelpDialog () {
        Object (
            title: _("Help with Dual Booting"),
            deletable: true,
            resizable: false
        );
    }

    construct {
        var header = new Gtk.HeaderBar ();
        header.set_show_close_button (true);
        var header_context = header.get_style_context ();
        // header_context.add_class ("default-decoration");

        var dual_booting = new Gtk.Label ("""<b>Create Partitions</b>
If you don't have available partitions, you can create them using the "Modify Partitions…" button to open GParted.

Select the wanted drive in the top-right of GParted. Resize the desired partition down to make room for a %s partition. If your previous install doesn't have a Swap partition, create one at the end of the unused space. In the remaining space, create a new partition to use as your root.

When you're ready, select the "Apply All Operations" icon at the end of the toolbar. Once the process is complete, close the GParted window and the installer will update with your changes.

<b>Choose Partitions</b>
Select the partition you want to use for the root of %s. Choose "Use partition" and select "Use as Root (/)". On EFI installs, you must also choose a Boot (/boot/efi) partition. One should exist from your other OS; choose it, and do not format it.

<b>Erase and Install</b>
Once you have your partition(s) selected, select the red "Erase and Install" button. This will apply your changes and begin the installation. When you restart your device after installing, it should automatically boot into %s where you can set up your user. Note that on BIOS installs, the %s entry may read "Ubuntu". To boot your other OS:

• If your device is in EFI mode, hold the spacebar while powering it on.
• If your device is in BIOS mode, a menu will automatically appear when powering on.

Choose your previous OS with the arrow keys, then press Enter.""".printf (os, os, os, os));
        dual_booting.margin = 12;
        dual_booting.max_width_chars = 90;
        dual_booting.use_markup = true;
        dual_booting.valign = Gtk.Align.START;
        dual_booting.wrap = true;

        var windows = new Gtk.Label ("""<b>Fast Startup</b>
Windows 8 and later uses a "Fast Startup" setting which prevents Windows from fully shutting down and allowing other OSes to use the disk. Before you can properly dual boot with Windows, you must disable this setting in Windows.

In your Windows install, open Control Panel and head to "Power Options". Select "Choose what the power buttons do", select "Change settings that are currently unavailable", then disable the "fast startup" setting. Note that Windows updates may occasionally turn this setting back on without asking, so if you are unable to boot into %s, check this setting first.

<b>Create Partitions</b>
Use the "Modify Partitions…" button to open GParted, then select the wanted drive in the top-right of GParted. Resize the desired partition down to make room for a %s partition. If your device is in EFI mode, create a new 512 MB FAT32 partition at the beginning of the unused space to be used as a Boot (/boot/efi) partition. Create a 4 GB swap partition at the end of the unused space. Create a partition from the the remaining space to be used as Root (/).

When you're ready, select the "Apply All Operations" icon at the end of the toolbar. Once the process is complete, close the GParted window and the installer will update with your changes.

<b>Choose Partitions</b>
Select the new FAT32 partition, choose "Use partition", and select "Use as Boot (/boot/efi)". Select the new partition you created for the root, choose "Use partition", and select "Use as Root (/)". Select the new Swap partition, choose "Use partition", and select "Use as Swap".

<b>Erase and Install</b>
Once you have your partitions selected, select the red "Erase and Install" button. This will apply your changes and begin the installation. When you restart your device after installing, it should automatically boot into %s where you can set up your user. Note that on BIOS installs, the %s entry may read "Ubuntu". To boot your other OS:

• If your device is in EFI mode, use your device's built-in boot menu (typically by holding a key during boot).
• If your device is in BIOS mode, a menu will automatically appear when powering on.

Choose your previous OS with the arrow keys, then press Enter.""".printf (os, os, os, os));
        windows.use_markup = true;
        windows.margin = 12;
        windows.max_width_chars = 90;
        windows.use_markup = true;
        windows.valign = Gtk.Align.START;
        windows.wrap = true;

        var stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        stack.add_titled (dual_booting, "dual_booting", _("Linux-based OSes"));
        stack.add_titled (windows, "windows", _("Windows"));

        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.set_stack (stack);

        header.set_custom_title (stack_switcher);
        set_titlebar (header);

        add (stack);
        set_position (Gtk.WindowPosition.CENTER);
        set_keep_above (true);
        stick ();
        show_all ();
    }
}

