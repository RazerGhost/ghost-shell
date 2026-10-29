#!/bin/sh
# Every picture the wallpaper picker offers, one path per line (grouped and paired by
# services/Wallpapers.js): yours first ($1, the folder from Settings), then Hyprland's, then the
# installed collections (/usr/share/wallpapers: CachyOS's and KDE Plasma's; /usr/share/backgrounds:
# nwg-shell's, Ubuntu's, ...). JPEG XL, AVIF and HEIC only when Qt can show them
# (kimageformats). Videos (live wallpapers) come as "<video><tab><thumbnail>": a frame made once
# with ffmpeg into ~/.cache/quickshell/wallpaper-thumbs, for the picker.
formats='png|jpe?g|webp'
[ -e /usr/lib/qt6/plugins/imageformats/kimg_jxl.so ] && formats="$formats|jxl"
[ -e /usr/lib/qt6/plugins/imageformats/kimg_avif.so ] && formats="$formats|avif"
[ -e /usr/lib/qt6/plugins/imageformats/kimg_heif.so ] && formats="$formats|heic|heif"

thumbs="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper-thumbs"

{
    [ -n "${1-}" ] && find "$1" -maxdepth 3 -type f 2>/dev/null | sort
    find /usr/share/hypr -maxdepth 1 -name 'wall*.png' 2>/dev/null | sort
    find /usr/share/wallpapers /usr/share/backgrounds -type f 2>/dev/null | sort
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
