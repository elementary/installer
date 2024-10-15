/*
 * Vala bindings for xkbregistry
 * Copyright 2022 Corentin Noël <corentin.noel@collabora.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

[CCode (cheader_filename = "xkbcommon/xkbregistry.h", cprefix = "rxkb_", lower_case_cprefix = "rxkb_")]
namespace Rxkb {
	[CCode (cname = "struct rxkb_context", ref_function = "rxkb_context_ref", unref_function = "rxkb_context_unref", has_type_id = false)]
	[Compact]
	public class Context {
		public Context (Rxkb.ContextFlags flags);
		public void set_log_level (Rxkb.LogLevel level);
		public Rxkb.LogLevel get_log_level ();
		public bool parse (string ruleset);
		public bool parse_default_ruleset ();
		public bool include_path_append (string path);
		public bool include_path_append_default ();
		public void set_log_fn (LogFn log_fn);
		public void set_user_data (void* user_data);
		public void* get_user_data ();
		[CCode (cname = "rxkb_model_first")]
		public unowned Rxkb.Model? get_first_model ();
		[CCode (cname = "rxkb_layout_first")]
		public unowned Rxkb.Layout? get_first_layout ();
		[CCode (cname = "rxkb_option_group_first")]
		public unowned Rxkb.OptionGroup? get_first_option_group ();
		public unowned Rxkb.Context @ref ();
		public void unref ();
	}

	[CCode (cname = "struct rxkb_model", ref_function = "rxkb_model_ref", unref_function = "rxkb_model_unref", has_type_id = false)]
	[Compact]
	public class Model {
		public unowned Rxkb.Model? next ();
		public unowned string get_name ();
		public unowned string? get_description ();
		public unowned string? get_vendor ();
		public Rxkb.Popularity get_popularity ();
		public unowned Rxkb.Model @ref ();
		public void unref ();
	}

	[CCode (cname = "struct rxkb_layout", ref_function = "rxkb_layout_ref", unref_function = "rxkb_layout_unref", has_type_id = false)]
	[Compact]
	public class Layout {
		public unowned Rxkb.Layout? next ();
		public unowned string get_name ();
		public unowned string? get_description ();
		public unowned string? get_variant ();
		public unowned string? get_brief ();
		[CCode (cname = "rxkb_layout_get_iso639_first")]
		public unowned Rxkb.Iso639Code? get_first_iso639 ();
		[CCode (cname = "rxkb_layout_get_iso3166_first")]
		public unowned Rxkb.Iso3166Code? get_first_iso3166 ();
		public unowned Rxkb.Layout @ref ();
		public void unref ();
	}

	[CCode (cname = "struct rxkb_option_group", ref_function = "rxkb_option_group_ref", unref_function = "rxkb_option_group_unref", has_type_id = false)]
	[Compact]
	public class OptionGroup {
		public unowned Rxkb.OptionGroup? next ();
		public unowned string get_name ();
		public unowned string? get_description ();
		public bool allows_multiple ();
		public Rxkb.Popularity get_popularity ();
		[CCode (cname = "rxkb_option_first")]
		public unowned Rxkb.Option? get_first_option ();
		public unowned Rxkb.OptionGroup @ref ();
		public void unref ();
	}

	[CCode (cname = "struct rxkb_option", ref_function = "rxkb_option_ref", unref_function = "rxkb_option_unref", has_type_id = false)]
	[Compact]
	public class Option {
		public unowned Rxkb.Option? next ();
		public unowned string get_name ();
		public unowned string? get_description ();
		public unowned string? get_brief ();
		public Rxkb.Popularity get_popularity ();
		public unowned Rxkb.Option @ref ();
		public void unref ();
	}

	[CCode (cname = "struct rxkb_iso639_code", ref_function = "rxkb_iso639_code_ref", unref_function = "rxkb_iso639_code_unref", has_type_id = false)]
	[Compact]
	public class Iso639Code {
		public unowned Rxkb.Iso639Code? next ();
		public unowned string get_code ();
		public unowned Rxkb.Iso639Code @ref ();
		public void unref ();
	}

	[CCode (cname = "struct rxkb_iso3166_code", ref_function = "rxkb_iso3166_code_ref", unref_function = "rxkb_iso3166_code_unref", has_type_id = false)]
	[Compact]
	public class Iso3166Code {
		public unowned Rxkb.Iso3166Code? next ();
		public unowned string get_code ();
		public unowned Rxkb.Iso3166Code @ref ();
		public void unref ();
	}

	[CCode (cname = "enum rxkb_context_flags", cprefix = "RXKB_CONTEXT_", has_type_id = false)]
	[Flags]
	public enum ContextFlags {
		NO_FLAGS,
		NO_DEFAULT_INCLUDES,
		LOAD_EXOTIC_RULES
	}

	[CCode (cname = "enum rxkb_popularity", cprefix = "RXKB_POPULARITY_", has_type_id = false)]
	public enum Popularity {
		STANDARD,
		EXOTIC
	}

	[CCode (cname = "enum rxkb_log_level", cprefix = "RXKB_LOG_LEVEL_", has_type_id = false)]
	public enum LogLevel {
		CRITICAL,
		ERROR,
		WARNING,
		INFO,
		DEBUG
	}

	[CCode (has_target = false, has_typedef = false)]
	public delegate void LogFn (Rxkb.Context ctx, Rxkb.LogLevel level, string format, va_list args);
}
