#!/bin/sh
# Every picture the wallpaper picker offers, one path per line (grouped and paired by
# services/Wallpapers.js): the ones in your folder ($1, from Settings). Not the system's
# collections (Hyprland's, CachyOS's, nwg-shell's; user's choice 2026-10-30: they weren't the art
# they want); the launcher's Wallpapers page finds more. JPEG XL, AVIF and HEIC only when Qt can show them
# (kimageformats). Videos (live wallpapers) come as "<video><tab><thumbnail>": a frame made once
# with ffmpeg into ~/.cache/quickshell/wallpaper-thumbs, for the picker.
formats='png|jpe?g|webp'
[ -e /usr/lib/qt6/plugins/imageformats/kimg_jxl.so ] && formats="$formats|jxl"
[ -e /usr/lib/qt6/plugins/imageformats/kimg_avif.so ] && formats="$formats|avif"
[ -e /usr/lib/qt6/plugins/imageformats/kimg_heif.so ] && formats="$formats|heic|heif"

thumbs="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper-thumbs"

{
    [ -n "${1-}" ] && find "$1" -maxdepth 3 -type f 2>/dev/null | sort
} | grep -iE "\.($formats|mp4|webm|mkv|mov)$" | while IFS= read -r path; do
    case "$path" in
        *.[mM][pP]4 | *.[wW][eE][bB][mM] | *.[mM][kK][vV] | *.[mM][oO][vV])
            mkdir -p "$thumbs"
            thumb="$thumbs/$(printf %s "$path" | md5sum | cut -d' ' -f1).jpg"
            [ -s "$thumb" ] || ffmpeg -nostdin -loglevel error -y -ss 1 -i "$path" -frames:v 1 \
                -vf scale=640:-2 "$thumb" 2>/dev/null || thumb=""
            printf '%s\t%s\n' "$path" "$thumb"
            ;;
        *) printf '%s\n' "$path" ;;
    esac
done
