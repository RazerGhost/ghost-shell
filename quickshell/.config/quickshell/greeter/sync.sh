#!/bin/sh
# Copies what the login screen shows into the folder it reads, /var/lib/qs-greeter/shared/:
# your settings (its look options), your colors, and the lock screen's picture (the one chosen in
# settings, else the desktop's). The login screen runs as greetd's "greeter" user, which can't
# read your home folder; update-greeter.sh made that folder yours, so no sudo is needed here.
# The shell runs this whenever one of those changes (lock/LoginScreenSync.qml), and
# update-greeter.sh runs it too.
set -eu

shared=/var/lib/qs-greeter/shared
state="$HOME/.local/state/quickshell"

# Not set up yet (update-greeter.sh hasn't run): nothing to do.
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

# The keyboard layout and touchpad settings (written by the shell's settings window); the login
# screen's Hyprland loads this copy (system/etc/greetd/hypr/hyprland.lua).
if [ -f "$HOME/.config/hypr/shell-settings.lua" ]; then
    copy "$HOME/.config/hypr/shell-settings.lua" "$shared/shell-settings.lua"
fi

picture=$(node -e '
    const read = file => { try { return require(file) } catch { return {} } };
    const [settings, wallpaper] = process.argv.slice(1).map(read);
    process.stdout.write(settings.lockWallpaper || wallpaper.path || "");
' "$state/settings.json" "$state/wallpaper.json")

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
