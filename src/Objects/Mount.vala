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

public class Installer.Mount {
    public string partition_path;
    public string parent_disk;
    public string mount_point;
    public Distinst.FileSystemType filesystem;
    public bool format;

    public Mount (string partition, string parent_disk, string mount,
                  bool format, Distinst.FileSystemType fs) {
        partition_path = partition;
        this.parent_disk = parent_disk;
        mount_point = mount;
        filesystem = fs;
        this.format = format;
    }

    public bool has_esp_fs () {
        return filesystem == Distinst.FileSystemType.FAT16
            || filesystem == Distinst.FileSystemType.FAT32;
    }
}
