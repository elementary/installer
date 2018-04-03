// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Michael Aaron Murphy <michael@system76.com>
 */

public class Installer.PartitionBar : Gtk.EventBox {
    public Gtk.Box container;

    public uint64 start;
    public uint64 end;
    public uint64 used;

    public Distinst.Partition* info;
    public Gtk.Label label;
    public PartitionMenu menu;

    public PartitionBar(Distinst.Partition* part, string parent_path,
                        uint64 sector_size, SetMount set_mount,
                        UnsetMount unset_mount) {
        start = part->get_start_sector ();
        end = part->get_end_sector ();

        var usage = part->sectors_used (sector_size);
        if (usage.tag == 1) {
            used = usage.value;
        } else {
            used = end - start;
        }

        string path = Utils.string_from_utf8 (part->get_device_path ());

        var fs = part->get_file_system ();
        var filesystem = Distinst.strfilesys (fs);

        label = new Gtk.Label ("%s (%s %s)".printf (
            path,
            filesystem,
            GLib.format_size ((end - start) * 512)
        ));

        label.use_markup = true;

        info = part;

        container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        container.pack_start (label, true, true, 0);
        var context = container.get_style_context ();
        context.add_class (filesystem);
        context.add_class ("partition");

        menu = new PartitionMenu (path, parent_path, set_mount, unset_mount);
        menu.relative_to = container;

        add(container);
    }

    public uint64 get_size () {
        return end - start;
    }

    public int get_percent(uint64 disk_sectors) {
        return (int) (((double) this.get_size () / (double) disk_sectors) * 100);
    }

    public void update_length (int alloc_width, uint64 disk_sectors) {
        var request = alloc_width / 100 * (int) get_percent (disk_sectors);
        container.set_size_request (request, -1);
    }

    public void show_popover () {
        menu.popup ();
    }
}
