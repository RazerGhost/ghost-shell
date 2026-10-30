#!/usr/bin/env bash
# More wallpapers: art from wallhaven.cc (anime by default, as you like them; never anything but
# its safe-for-work purity), downloaded into your wallpaper folder (Settings' wallpaperFolder,
# ~/Pictures/Wallpapers by default), never into the repo. No account: wallhaven's public search
# API. `ghost wallpapers` runs this; the desktop editor's Wallpaper tab too.
#
#   ghost wallpapers get [--style S] [--count N] [--general] [--] [search words]
#       the month's best (or the best matching the words), at least 1920x1080 in 16:9; N of them
#       (12 by default, at most 48) that aren't in the folder yet. --general: illustrations and
#       scenery too, not only anime. --style: the all-time favourites of one of the styles you
#       like (words added narrow it further):
#         sky        scenery, big clouds, cities at dusk, trains ("clouds")
#         lofi       cozy rooms, rain on windows ("indoors +window")
#         painterly  painted illustration, anime or not ("digital painting", with --general)
#         minimal    one figure or shape and a lot of empty space ("+minimalism -text"; suits the
#                    lock screen's quiet side)
#       Each search was tried on wallhaven (2026-10-30): its favourites' tags match the style.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

[[ ${1:-} == get ]] || fail "usage: ghost wallpapers get [--style sky|lofi|painterly|minimal] [search words] [--count N] [--general]"
shift
count=12 categories=010 words=() style=""
while (($#)); do
    case $1 in
        --count) [[ ${2:-} =~ ^[0-9]+$ ]] || fail "--count needs a number"; count=$((10#$2)); shift 2 ;;
        --general) categories=110; shift ;;
        --style) [[ -n ${2:-} ]] || fail "--style needs a style"; style=$2; shift 2 ;;
        # The rest are search words, even ones starting with "--" (the shell's search field).
        --) shift; words+=("$@"); break ;;
        *) words+=("$1"); shift ;;
    esac
done
((count >= 1 && count <= 48)) || fail "--count is 1 to 48"

# A style's search words go first, the typed ones after; its favourites instead of the month's best.
sorting=""
case $style in
    "") ;;
    sky) words=(clouds "${words[@]}") ;;
    lofi) words=(indoors +window "${words[@]}") ;;
    painterly) words=(digital painting "${words[@]}"); categories=110 ;;
    minimal) words=(+minimalism -text "${words[@]}") ;;
    *) fail "--style is sky, lofi, painterly or minimal" ;;
esac
[[ -n $style ]] && sorting=favorites

# The folder the shell uses: Settings' wallpaperFolder ("~/" allowed), else the default.
folder=$(SETTINGS="$HOME/.local/state/quickshell/settings.json" bun -e '
    const fs = require("fs");
    let folder = "";
    try { folder = JSON.parse(fs.readFileSync(process.env.SETTINGS, "utf8")).wallpaperFolder || ""; } catch {}
    folder = folder.replace(/^~(?=\/|$)/, process.env.HOME);
    process.stdout.write(folder || process.env.HOME + "/Pictures/Wallpapers");
')
mkdir -p "$folder"

# The search, in wallhaven's API: SFW only (purity=100), the chosen categories, big enough, 16:9;
# the words as a query, else the month's top list. Pages until there are enough new ones.
got=0 failed=0 page=1
while ((got < count && page <= 5)); do
    url=$(WORDS="${words[*]}" CATS=$categories PAGE=$page SORTING=$sorting bun -e '
        const q = process.env.WORDS.trim();
        const params = new URLSearchParams({ categories: process.env.CATS, purity: "100", atleast: "1920x1080",
                                             ratios: "16x9", page: process.env.PAGE,
                                             sorting: process.env.SORTING || (q ? "relevance" : "toplist"), topRange: "1M" });
        if (q) params.set("q", q);
        process.stdout.write("https://wallhaven.cc/api/v1/search?" + params);
    ')
    list=$(curl -fsS --max-time 20 "$url") || fail "wallhaven didn't answer (no network?)"
    # One "<id> <extension> <url>" per picture: safe for work, a JPEG or PNG, from wallhaven's own
    # file host, its id letters and digits only (the file name is made from it).
    mapfile -t found < <(LIST="$list" bun -e '
        const data = JSON.parse(process.env.LIST).data ?? [];
        const ext = { "image/jpeg": "jpg", "image/png": "png" };
        for (const w of data)
            if (w.purity === "sfw" && ext[w.file_type] && /^[a-z0-9]+$/i.test(w.id)
                && /^https:\/\/w\.wallhaven\.cc\/full\/[a-z0-9]+\/wallhaven-[a-z0-9]+\.(jpg|png)$/i.test(w.path))
                console.log(w.id + " " + ext[w.file_type] + " " + w.path);
    ')
    ((${#found[@]})) || break
    for entry in "${found[@]}"; do
        ((got < count)) || break
        read -r id ext src <<<"$entry"
        file="$folder/wallhaven-$id.$ext"
        [[ -e $file ]] && continue
        if curl -fsS --max-time 60 -o "$file.part" "$src"; then
            mv "$file.part" "$file"
            got=$((got + 1))
            echo "  $(basename "$file")"
        else
            rm -f "$file.part"
            failed=$((failed + 1))
        fi
    done
    page=$((page + 1))
done
echo "$got new wallpapers in $folder (from wallhaven.cc)$( ((failed)) && echo ", $failed couldn't be downloaded")."
