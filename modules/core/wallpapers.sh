#!/usr/bin/env bash
# More wallpapers: art from wallhaven.cc (anime by default, as you like them; never anything but
# its safe-for-work purity), downloaded into your wallpaper folder (Settings' wallpaperFolder,
# ~/Pictures/Wallpapers by default), never into the repo. No account: wallhaven's public search
# API. `ghost wallpapers` runs this; the shell's Wallpapers window runs `fetch` for the one you pick.
# The searches, the styles and the checks on each result are the shell's
# services/Wallhaven.js (tested), loaded with js_with.
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
#   ghost wallpapers fetch <id>
#       one picture by its wallhaven id (checked like the search's); prints its path.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh
lib=quickshell/.config/quickshell/services/Wallhaven.js

usage="usage: ghost wallpapers get [--style sky|lofi|painterly|minimal] [search words] [--count N] [--general]
       ghost wallpapers fetch <id>"
action=${1:-}
[[ $action == get || $action == fetch ]] || fail "$usage"
shift

# The folder the shell uses: Settings' wallpaperFolder ("~/" allowed), else the default.
folder=$(SETTINGS="$HOME/.local/state/quickshell/settings.json" bun -e '
    const fs = require("fs");
    let folder = "";
    try { folder = JSON.parse(fs.readFileSync(process.env.SETTINGS, "utf8")).wallpaperFolder || ""; } catch {}
    folder = folder.replace(/^~(?=\/|$)/, process.env.HOME);
    process.stdout.write(folder || process.env.HOME + "/Pictures/Wallpapers");
')
mkdir -p "$folder"

# Downloads "<file> <url>" (a checked result) unless it's there; 0 if it came or was there.
download() {
    local file=$folder/$1
    [[ -e $file ]] && return 0
    if curl -fsS --max-time 60 -o "$file.part" "$2"; then
        mv "$file.part" "$file"
    else
        rm -f "$file.part"
        return 1
    fi
}

if [[ $action == fetch ]]; then
    (($# == 1)) || fail "$usage"
    url=$(ID=$1 js_with "$lib" 'process.stdout.write(lib.pictureUrl(process.env.ID))')
    [[ -n $url ]] || fail "not a wallhaven id: $1"
    answer=$(curl -fsS --max-time 20 "$url") || fail "wallhaven didn't answer (no network?)"
    read -r file src < <(ANSWER=$answer js_with "$lib" '
        let p = null;
        try { p = lib.picture(JSON.parse(process.env.ANSWER).data); } catch {}
        if (p) console.log(p.file + " " + p.url);
    ') || fail "wallhaven's answer for $1 isn't a safe-for-work JPEG or PNG"
    download "$file" "$src" || fail "couldn't download $file"
    echo "$folder/$file"
    exit 0
fi

count=12 general=false words=() style=""
while (($#)); do
    case $1 in
        --count) [[ ${2:-} =~ ^[0-9]+$ ]] || fail "--count needs a number"; count=$((10#$2)); shift 2 ;;
        --general) general=true; shift ;;
        --style) [[ -n ${2:-} ]] || fail "--style needs a style"; style=$2; shift 2 ;;
        # The rest are search words, even ones starting with "--" (the shell's search field).
        --) shift; words+=("$@"); break ;;
        *) words+=("$1"); shift ;;
    esac
done
((count >= 1 && count <= 48)) || fail "--count is 1 to 48"
[[ -z $style ]] || STYLE=$style js_with "$lib" 'process.exit(lib.style(process.env.STYLE) ? 0 : 1)' \
    || fail "--style is sky, lofi, painterly or minimal"

# Pages until there are enough new ones.
got=0 failed=0 page=1
while ((got < count && page <= 5)); do
    url=$(WORDS="${words[*]}" STYLE=$style PAGE=$page GENERAL=$general js_with "$lib" '
        const words = process.env.WORDS.split(/\s+/).filter(w => w !== "");
        process.stdout.write(lib.searchUrl(words, process.env.STYLE, Number(process.env.PAGE), process.env.GENERAL === "true"));
    ')
    list=$(curl -fsS --max-time 20 "$url") || fail "wallhaven didn't answer (no network?)"
    # One "<file> <url>" per checked picture.
    mapfile -t found < <(LIST=$list js_with "$lib" '
        for (const p of lib.results(process.env.LIST).pictures)
            console.log(p.file + " " + p.url);
    ')
    ((${#found[@]})) || break
    for entry in "${found[@]}"; do
        ((got < count)) || break
        read -r file src <<<"$entry"
        [[ -e $folder/$file ]] && continue
        if download "$file" "$src"; then
            got=$((got + 1))
            echo "  $file"
        else
            failed=$((failed + 1))
        fi
    done
    page=$((page + 1))
done
echo "$got new wallpapers in $folder (from wallhaven.cc)$( ((failed)) && echo ", $failed couldn't be downloaded")."
