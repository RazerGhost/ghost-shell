#!/bin/sh
# Sets the wallpaper and the colors that come from it. Used by the shell's wallpaper picker
# (quickshell's services/Wallpaper.qml) and by `dots theme` and the core module's setup:
#   wallpaper.sh <image>     the image becomes the wallpaper, and matugen colors everything from it
#   wallpaper.sh '#rrggbb'   colors from a seed color instead; the wallpaper stays as it is
#   wallpaper.sh             colors again from the current wallpaper (renders templates added
#                            since); with no wallpaper, from the default seed, the first time only
set -eu

state="$HOME/.local/state/quickshell"
# The Material baseline purple: the same scheme as the fallbacks in quickshell's Colors.qml.
default_seed="#6750a4"

from_image() { matugen image "$1" -m dark --source-color-index 0; }
from_seed() { matugen color hex "$1" -m dark; }

case "${1-}" in
    "#"*)
        from_seed "$1"
        ;;
    "")
        current=$(node -e 'process.stdout.write(require(process.argv[1]).path || "")' \
            "$state/wallpaper.json" 2>/dev/null || true)
        if [ -n "$current" ] && [ -f "$current" ]; then
            echo "Colors from the current wallpaper: $current"
            from_image "$current"
        elif [ -f "$state/colors.json" ]; then
            echo "Colors already generated; pass a wallpaper or a hex color to regenerate."
        else
            echo "No wallpaper yet: colors from the seed color $default_seed"
            from_seed "$default_seed"
        fi
        ;;
    *)
        [ -f "$1" ] || { echo "wallpaper not found: $1" >&2; exit 1; }
        # The shell's wallpaper service watches this file and draws the picture it names.
        mkdir -p "$state"
        WALLPAPER=$(realpath "$1") node -e '
            require("fs").writeFileSync(process.argv[1], JSON.stringify({ path: process.env.WALLPAPER }, null, 4) + "\n");
        ' "$state/wallpaper.json"
        from_image "$(realpath "$1")"
        ;;
esac
