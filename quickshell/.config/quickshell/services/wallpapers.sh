#!/bin/sh
# Every picture the wallpaper picker offers, one path per line (grouped and paired by
# services/Wallpapers.js): yours first ($1, the folder from Settings), then Hyprland's, then the
# installed collections (/usr/share/wallpapers: CachyOS's and KDE Plasma's; /usr/share/backgrounds:
# nwg-shell's, Ubuntu's, ...). JPEG XL, AVIF and HEIC only when Qt can show them
# (kimageformats).
formats='png|jpe?g|webp'
[ -e /usr/lib/qt6/plugins/imageformats/kimg_jxl.so ] && formats="$formats|jxl"
[ -e /usr/lib/qt6/plugins/imageformats/kimg_avif.so ] && formats="$formats|avif"
[ -e /usr/lib/qt6/plugins/imageformats/kimg_heif.so ] && formats="$formats|heic|heif"

{
    [ -n "${1-}" ] && find "$1" -maxdepth 3 -type f 2>/dev/null | sort
    find /usr/share/hypr -maxdepth 1 -name 'wall*.png' 2>/dev/null | sort
    find /usr/share/wallpapers /usr/share/backgrounds -type f 2>/dev/null | sort
} | grep -iE "\.($formats)$"
