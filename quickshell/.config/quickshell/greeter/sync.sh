#!/bin/sh
# Copies what the login screen shows into the folder it reads, /var/lib/qs-greeter/shared/:
# your settings (its look options), your colors, your picture (~/.face) and the lock screen's
# picture (the first argument). The login screen runs as greetd's "greeter" user, which can't
# read your home folder; modules/core/greeter.sh made that folder yours, so no sudo is needed here.
# The shell runs this whenever one of those changes (lock/LoginScreenSync.qml), and
# modules/core/greeter.sh runs it too.
set -eu

shared=/var/lib/qs-greeter/shared
state="$HOME/.local/state/quickshell"

# Not set up yet (`ghost greeter` hasn't run): nothing to do.
[ -w "$shared" ] || exit 0

# Write to a temporary name first, so the login screen never reads a half-copied file.
copy() {
    cp "$1" "$2.tmp"
    mv -f "$2.tmp" "$2"
}

for file in settings.json colors.json; do
    if [ -f "$state/$file" ]; then
        copy "$state/$file" "$shared/$file"
    fi
done

# Your picture (~/.face, chosen in Settings -> Lock screen), shown above your name.
if [ -f "$HOME/.face" ]; then
    cmp -s "$HOME/.face" "$shared/face" || copy "$HOME/.face" "$shared/face"
else
    rm -f "$shared/face"
fi

# The keyboard layout and touchpad settings (written by the shell's settings window); the login
# screen's Hyprland loads this copy (system/etc/greetd/hypr/hyprland.lua). Without game mode's
# block (settings/HyprlandConfig.js): logging out with game mode on mustn't leave the login
# screen without animations; nor the windows editor's rule at the end (HyprlandRuntime.qml).
if [ -f "$HOME/.config/hypr/shell-settings.lua" ]; then
    sed -e '/^-- Game mode is on/,/^})$/d' -e '/^-- While the windows editor is open/,$d' \
        "$HOME/.config/hypr/shell-settings.lua" >"$shared/shell-settings.lua.tmp"
    mv -f "$shared/shell-settings.lua.tmp" "$shared/shell-settings.lua"
fi

# The lock screen's picture, from the shell (lock/LoginScreenSync.qml passes Wallpaper.lockPath;
# "" for none). Without an argument (modules/core/greeter.sh), the login screen keeps its picture until
# the shell runs this again at its next start.
[ $# -ge 1 ] || exit 0
picture=$1

if [ -n "$picture" ] && [ -f "$picture" ]; then
    target="$shared/picture.${picture##*.}"
    # The pictures can be large (tens of MB): only copy a different one.
    if ! cmp -s "$picture" "$target"; then
        rm -f "$shared"/picture.*
        copy "$picture" "$target"
    fi
    printf '{ "path": "%s" }\n' "$target" > "$shared/wallpaper.json.tmp"
    mv -f "$shared/wallpaper.json.tmp" "$shared/wallpaper.json"
else
    # No picture: the login screen shows its plain background color.
    rm -f "$shared"/picture.*
    printf '{ "path": "" }\n' > "$shared/wallpaper.json"
fi
