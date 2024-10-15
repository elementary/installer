/*-
 * Copyright 2019 elementary, Inc (https://elementary.io)
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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Installer.KeyboardLayout : GLib.Object {

    // Based on https://github.com/mike-fabian/langtable/blob/master/langtable/data/keyboards.xml
    public const string[] NON_LATIN_LAYOUTS = {
        "af",
        "af(fa-olpc)",
        "af(olpc-ps)",
        "af(ps)",
        "af(uz)",
        "af(uz-olpc)",
        "am",
        "am(eastern)",
        "am(eastern-alt)",
        "am(phonetic)",
        "am(phonetic-alt)",
        "am(western)",
        "ara",
        "ara(azerty)",
        "ara(azerty_digits)",
        "ara(buckwalter)",
        "ara(digits)",
        "ara(qwerty)",
        "ara(qwerty_digits)",
        "az(cyrillic)",
        "bd",
        "bd(probhat)",
        "bg",
        "bg(bas_phonetic)",
        "bg(phonetic)",
        "brai",
        "brai(left_hand)",
        "brai(right_hand)",
        "bt",
        "by",
        "by(legacy)",
        "ca(ike)",
        "ca(multi-2gr)",
        "cn(tib)",
        "cn(tib_asciinum)",
        "cn(ug)",
        "cz(ucw)",
        "de(ru)",
        "et",
        "fr(geo)",
        "ge",
        "ge(os)",
        "gr",
        "gr(extended)",
        "gr(nodeadkeys)",
        "gr(polytonic)",
        "gr(simple)",
        "il",
        "il(biblical)",
        "il(lyx)",
        "il(phonetic)",
        "in",
        "in(ben)",
        "in(ben_baishakhi)",
        "in(ben_bornona)",
        "in(ben_gitanjali)",
        "in(ben_inscript)",
        "in(ben_probhat)",
        "in(bolnagri)",
        "in(deva)",
        "in(guj)",
        "in(guru)",
        "in(hin-kagapa)",
        "in(hin-wx)",
        "in(jhelum)",
        "in(kan)",
        "in(kan-kagapa)",
        "in(mal)",
        "in(mal_enhanced)",
        "in(mal_lalitha)",
        "in(mar-kagapa)",
        "in(ori)",
        "in(san-kagapa)",
        "in(tam)",
        "in(tam_TAB)",
        "in(tam_TSCII)",
        "in(tam_keyboard_with_numerals)",
        "in(tam_unicode)",
        "in(tel)",
        "in(tel-kagapa)",
        "in(urd-phonetic)",
        "in(urd-phonetic3)",
        "in(urd-winkeys)",
        "iq",
        "ir",
        "ir(pes_keypad)",
        "jp(kana)",
        "jp(mac)",
        "kg",
        "kg(phonetic)",
        "kh",
        "kz",
        "kz(kazrus)",
        "kz(ruskaz)",
        "la",
        "la(stea)",
        "lk",
        "lk(tam_TAB)",
        "lk(tam_unicode)",
        "ma",
        "ma(tifinagh)",
        "ma(tifinagh-alt)",
        "ma(tifinagh-alt-phonetic)",
        "ma(tifinagh-extended)",
        "ma(tifinagh-extended-phonetic)",
        "ma(tifinagh-phonetic)",
        "me(cyrillic)",
        "me(cyrillicalternatequotes)",
        "me(cyrillicyz)",
        "mk",
        "mk(nodeadkeys)",
        "mm",
        "mn",
        "mv",
        "ng(hausa)",
        "ng(igbo)",
        "ng(yoruba)",
        "np",
        "ph(capewell-dvorak-bay)",
        "ph(capewell-qwerf2k6-bay)",
        "ph(colemak-bay)",
        "ph(dvorak-bay)",
        "ph(qwerty-bay)",
        "pk",
        "pk(ara)",
        "pk(snd)",
        "pk(urd-crulp)",
        "pk(urd-nla)",
        "pl(ru_phonetic_dvorak)",
        "rs",
        "rs(alternatequotes)",
        "rs(rue)",
        "rs(yz)",
        "ru",
        "ru(bak)",
        "ru(chm)",
        "ru(cv)",
        "ru(dos)",
        "ru(kom)",
        "ru(legacy)",
        "ru(mac)",
        "ru(os_legacy)",
        "ru(os_winkeys)",
        "ru(phonetic)",
        "ru(phonetic_winkeys)",
        "ru(sah)",
        "ru(srp)",
        "ru(tt)",
        "ru(typewriter)",
        "ru(typewriter-legacy)",
        "ru(udm)",
        "ru(xal)",
        "se(ru)",
        "se(rus_nodeadkeys)",
        "se(swl)",
        "sy",
        "sy(syc)",
        "sy(syc_phonetic)",
        "th",
        "th(pat)",
        "th(tis)",
        "tj",
        "tj(legacy)",
        "tz",
        "ua",
        "ua(homophonic)",
        "ua(legacy)",
        "ua(phonetic)",
        "ua(rstu)",
        "ua(rstu_ru)",
        "ua(typewriter)",
        "ua(winkeys)",
        "us(chr)",
        "us(rus)",
        "uz"
    };

    public string name { get; construct; }
    public string original_name { get; construct; }
    public string display_name {
        get {
            return dgettext ("xkeyboard-config", original_name);
        }
    }

    private GLib.ListStore variants_store;

    public KeyboardLayout (string name, string original_name) {
        Object (name: name, original_name: original_name);
    }

    construct {
        variants_store = new GLib.ListStore (typeof (KeyboardVariant));
        variants_store.append (new KeyboardVariant (this, null, null));
    }

    public void add_variant (string name, string original_name) {
        var variant = new KeyboardVariant (this, name, original_name);
        variants_store.insert_sorted (variant, (GLib.CompareDataFunc<GLib.Object>) KeyboardVariant.compare);
    }

    public bool has_variants () {
        return variants_store.get_n_items () > 1;
    }

    public unowned GLib.ListStore get_variants () {
        return variants_store;
    }

    public GLib.Variant to_gsd_variant () {
        if (!(name in NON_LATIN_LAYOUTS)) {
            // Layout can type latin characters, return a single layout
            return new GLib.Variant.array (new VariantType ("(ss)"), { new GLib.Variant ("(ss)", "xkb", name) });
        } else {
            // User's layout doesn't use latin characters, also add US layout so they can type a username and password
            var en_us = new GLib.Variant ("(ss)", "xkb", "us");
            var primary_layout = new GLib.Variant ("(ss)", "xkb", name);
            return new GLib.Variant.array (new VariantType ("(ss)"), { en_us, primary_layout });
        }
    }

    public static int compare (KeyboardLayout a, KeyboardLayout b) {
        return a.display_name.collate (b.display_name);
    }

    public static GLib.ListStore get_all () {
        var layout_store = new GLib.ListStore (typeof (KeyboardLayout));

        var xkb_context = new Rxkb.Context (NO_FLAGS);
        xkb_context.parse_default_ruleset ();

        var xkb_layout = xkb_context.get_first_layout ();
        while (xkb_layout != null) {
            var layout = new KeyboardLayout (xkb_layout.get_name (), xkb_layout.get_description ());
            layout_store.insert_sorted (layout, (GLib.CompareDataFunc<GLib.Object>) KeyboardLayout.compare);

            var next_layout = xkb_layout.next ();
            while (next_layout != null && next_layout.get_variant () != null) {
                layout.add_variant (next_layout.get_variant (), next_layout.get_description ());

                next_layout = next_layout.next ();
            }

            xkb_layout = next_layout;
        }

        return layout_store;
    }
}
