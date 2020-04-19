// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
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
 */

namespace KeyboardLayoutHelper {
    public const string XKB_RULES_FILE = "base.xml";

    public struct Layout {
        public string name;
        public string description;
        public Gee.HashMap<string, string> variants;
    }

    public string get_xml_rules_file_path () {
        unowned string? base_path = GLib.Environment.get_variable ("XKB_CONFIG_ROOT");
        if (base_path == null) {
            base_path = Build.XKB_BASE;
        }

        return Path.build_filename (base_path, "rules", XKB_RULES_FILE);
    }

    public static Gee.LinkedList<Layout?> get_layouts () {
        var layouts = new Gee.LinkedList<Layout?> ();
        unowned Xml.Doc* doc = Xml.Parser.read_file (get_xml_rules_file_path ());
        Xml.Node* root = doc->get_root_element ();
        Xml.Node* layout_list_node = get_xml_node_by_name (root, "layoutList");
        if (layout_list_node == null) {
            delete doc;
            return layouts;
        }

        for (Xml.Node* layout_iter = layout_list_node->children; layout_iter != null; layout_iter = layout_iter->next) {
            if (layout_iter->type == Xml.ElementType.ELEMENT_NODE) {
                if (layout_iter->name == "layout") {
                    Xml.Node* config_node = get_xml_node_by_name (layout_iter, "configItem");
                    Xml.Node* variant_node = get_xml_node_by_name (layout_iter, "variantList");
                    Xml.Node* description_node = get_xml_node_by_name (config_node, "description");
                    Xml.Node* name_node = get_xml_node_by_name (config_node, "name");
                    if (name_node == null || description_node == null) {
                        continue;
                    }

                    var layout = Layout ();
                    layout.name = name_node->children->content;
                    layout.description = dgettext ("xkeyboard-config", description_node->children->content);
                    var variants = new Gee.HashMap<string, string> ();
                    layout.variants = variants;
                    if (variant_node != null) {
                        for (Xml.Node* variant_iter = variant_node->children; variant_iter != null; variant_iter = variant_iter->next) {
                            if (variant_iter->name == "variant") {
                                Xml.Node* variant_config_node = get_xml_node_by_name (variant_iter, "configItem");
                                if (variant_config_node != null) {
                                    Xml.Node* variant_description_node = get_xml_node_by_name (variant_config_node, "description");
                                    Xml.Node* variant_name_node = get_xml_node_by_name (variant_config_node, "name");
                                    if (variant_description_node != null && variant_name_node != null) {
                                        variants[variant_name_node->children->content] = dgettext ("xkeyboard-config", variant_description_node->children->content);
                                    }
                                }
                            }
                        }
                    }

                    layouts.add (layout);
                }
            }
        }

        delete doc;
        return layouts;
    }

    private static Xml.Node* get_xml_node_by_name (Xml.Node* root, string name) {
        for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if (iter->type == Xml.ElementType.ELEMENT_NODE) {
                if (iter->name == name) {
                    return iter;
                }
            }
        }

        return null;
    }
}
