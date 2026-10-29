#!/bin/sh
# Sets the wallpaper and the colors that come from it. Used by the shell's wallpaper picker
# (quickshell's services/Wallpaper.qml) and by `ghost theme` and the core module's setup:
#   wallpaper.sh <image>     the image becomes the wallpaper, and matugen colors everything from it
#   wallpaper.sh '#rrggbb'   colors from a seed color instead; the wallpaper stays as it is
#   wallpaper.sh             colors again from the current wallpaper (renders templates added
#                            since, or after switching between light and dark); with no
#                            wallpaper, from the last seed color (the default one at first)
# Light or dark, the color style, contrast and accent come from the shell (Settings ->
# Appearance), which writes them to ~/.local/state/quickshell/scheme; dark when that's missing.
# GTK apps get light or dark through gsettings.
set -eu

state="$HOME/.local/state/quickshell"
# The Material baseline purple: the same scheme as the fallbacks in quickshell's Colors.qml.
default_seed="#6750a4"

# How to make the colors, from the shell's Settings -> Appearance ($state/scheme, "key=value"
# lines; services/ColorScheme.js writes it): light or dark, matugen's color style and contrast,
# and a fixed accent color ("" = the wallpaper's). Each value is checked again here, so the file
# can't make this run anything else; an older file with just "light" or "dark" still works.
mode=dark type=scheme-tonal-spot contrast=0 accent= icons=Colloid
if [ -f "$state/scheme" ]; then
    while IFS='=' read -r key value; do
        case "$key=$value" in
            mode=light | light=) mode=light ;;
            type=scheme-[a-z-]*) type=$value ;;
            accent=\#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) accent=$value ;;
            icons=*[!A-Za-z0-9_-]*) ;;
            icons=?*) icons=$value ;;
        esac
        case "$key" in
            contrast) case "$value" in -1 | -0.5 | 0 | 0.5 | 1) contrast=$value ;; esac ;;
        esac
    done < "$state/scheme"
fi

scheme() { matugen "$@" -m "$mode" -t "$type" --contrast "$contrast"; }
# A fixed accent wins over the picture (the wallpaper itself still shows).
from_image() {
    if [ -n "$accent" ]; then
        scheme color hex "$accent"
    else
        scheme image "$1" --source-color-index 0
    fi
}
# The picture to make colors from: the picture itself, or for a video (a live wallpaper) a frame
# of it, kept as video-frame.jpg (the lock and login screens show that frame).
picture_of() {
    case "$1" in
        *.[mM][pP]4 | *.[wW][eE][bB][mM] | *.[mM][kK][vV] | *.[mM][oO][vV])
            ffmpeg -nostdin -loglevel error -y -ss 1 -i "$1" -frames:v 1 "$state/video-frame.jpg" \
                && echo "$state/video-frame.jpg"
            ;;
        *) echo "$1" ;;
    esac
}
from_seed() {
    mkdir -p "$state"
    printf '%s\n' "$1" > "$state/seed"
    scheme color hex "${accent:-$1}"
}

case "${1-}" in
    "#"*)
        from_seed "$1"
        ;;
    "")
        current=$(bun -e 'process.stdout.write(require(process.argv[1]).path || "")' \
            "$state/wallpaper.json" 2>/dev/null || true)
        if [ -n "$current" ] && [ -f "$current" ]; then
            echo "Colors from the current wallpaper: $current"
            from_image "$(picture_of "$current")"
        else
            seed=$(cat "$state/seed" 2>/dev/null || echo "$default_seed")
            echo "No wallpaper: colors from the seed color $seed"
            from_seed "$seed"
        fi
        ;;
    *)
        [ -f "$1" ] || { echo "wallpaper not found: $1" >&2; exit 1; }
        mkdir -p "$state"
        # A video's frame first: the shell shows it as soon as the file below names the video.
        picture=$(picture_of "$(realpath "$1")")
        # The shell's wallpaper service watches this file and draws the picture it names.
        WALLPAPER=$(realpath "$1") bun -e '
            require("fs").writeFileSync(process.argv[1], JSON.stringify({ path: process.env.WALLPAPER }, null, 4) + "\n");
        ' "$state/wallpaper.json"
        from_image "$picture"
        ;;
esac

# The icon theme's version for this mode: Colloid-Teal-Dark / -Light, breeze-dark, or the theme
# itself when it has no such version.
icon_theme() {
    for name in "$@"; do
        for dir in "$HOME/.local/share/icons" /usr/share/icons; do
            [ -f "$dir/$name/index.theme" ] && { echo "$name"; return; }
        done
    done
    echo Colloid-Dark
}
if [ "$mode" = light ]; then
    icon_name=$(icon_theme "$icons-Light" "$icons")
else
    icon_name=$(icon_theme "$icons-Dark" "$icons-dark" "$icons")
fi
# The shell reads it when it starts (hypr/shell.sh sets QS_ICON_THEME from it).
mkdir -p "$state"
printf '%s\n' "$icon_name" > "$state/icon-theme"

# GTK 4 apps follow color-scheme; adw-gtk3 makes GTK 3 ones match.
if [ "$mode" = light ]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
fi
gsettings set org.gnome.desktop.interface icon-theme "$icon_name"
