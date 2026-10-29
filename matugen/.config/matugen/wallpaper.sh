#!/bin/sh
# Sets the wallpaper and the colors that come from it. Used by the shell's wallpaper picker
# (quickshell's services/Wallpaper.qml) and by `ghost theme` and the core module's setup:
#   wallpaper.sh <image>     the image becomes the wallpaper, and matugen colors everything from it
#   wallpaper.sh '#rrggbb'   colors from a seed color instead; the wallpaper stays as it is
#   wallpaper.sh             colors again from the current wallpaper (renders templates added
#                            since, or after switching between light and dark); with no
#                            wallpaper, from the last seed color (the default one at first)
# Light or dark comes from the shell (Settings -> Appearance), which writes it to
# ~/.local/state/quickshell/scheme; dark when that's missing. GTK apps get it through gsettings.
set -eu

state="$HOME/.local/state/quickshell"
# The Material baseline purple: the same scheme as the fallbacks in quickshell's Colors.qml.
default_seed="#6750a4"

mode=$(cat "$state/scheme" 2>/dev/null || true)
[ "$mode" = light ] || mode=dark

from_image() { matugen image "$1" -m "$mode" --source-color-index 0; }
from_seed() {
    mkdir -p "$state"
    printf '%s\n' "$1" > "$state/seed"
    matugen color hex "$1" -m "$mode"
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
            from_image "$current"
        else
            seed=$(cat "$state/seed" 2>/dev/null || echo "$default_seed")
            echo "No wallpaper: colors from the seed color $seed"
            from_seed "$seed"
        fi
        ;;
    *)
        [ -f "$1" ] || { echo "wallpaper not found: $1" >&2; exit 1; }
        # The shell's wallpaper service watches this file and draws the picture it names.
        mkdir -p "$state"
        WALLPAPER=$(realpath "$1") bun -e '
            require("fs").writeFileSync(process.argv[1], JSON.stringify({ path: process.env.WALLPAPER }, null, 4) + "\n");
        ' "$state/wallpaper.json"
        from_image "$(realpath "$1")"
        ;;
esac

# GTK 4 apps follow color-scheme; adw-gtk3 makes GTK 3 ones match. Colloid's -Dark and -Light
# icons are drawn for dark and light backgrounds.
if [ "$mode" = light ]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
    gsettings set org.gnome.desktop.interface icon-theme Colloid-Light
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    gsettings set org.gnome.desktop.interface icon-theme Colloid-Dark
fi
