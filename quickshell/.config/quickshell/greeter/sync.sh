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

if [ -f "$state/colors.json" ]; then
    copy "$state/colors.json" "$shared/colors.json"
    # The background color alone, as data (rrggbb), for the login screen's Hyprland to start on
    # (system/etc/greetd/hypr/hyprland.lua checks it): no Lua from here runs there.
    surface=$(sed -n 's/^ *"surface": *"#\([0-9a-fA-F]\{6\}\)".*/\1/p' "$state/colors.json")
    if [ -n "$surface" ]; then
        printf '%s\n' "$surface" >"$shared/background.tmp"
        mv -f "$shared/background.tmp" "$shared/background"
    fi
fi

# Only the settings the login screen uses: its look (the lock screen's and the login screen's
# options, the clock, fonts, size, glass), not the rest of yours (launcher commands, apps, the
# weather town). Keys it doesn't get keep their defaults there.
if [ -f "$state/settings.json" ]; then
    SETTINGS="$state/settings.json" bun -e '
        const all = JSON.parse(require("fs").readFileSync(process.env.SETTINGS, "utf8"));
        const keep = ["uiScale", "textScale", "cornerScale", "animationSpeed", "glass", "glassOpacity", "clock24Hour"];
        const shown = Object.fromEntries(Object.entries(all).filter(([key]) =>
            (keep.includes(key) || /^(lock|greeter|font)/.test(key)) && key !== "lockLooks"));
        process.stdout.write(JSON.stringify(shown, null, 4) + "\n");
    ' >"$shared/settings.json.tmp"
    mv -f "$shared/settings.json.tmp" "$shared/settings.json"
fi

# Your picture (~/.face, chosen in Settings -> Lock screen), shown above your name.
if [ -f "$HOME/.face" ]; then
    cmp -s "$HOME/.face" "$shared/face" || copy "$HOME/.face" "$shared/face"
else
    rm -f "$shared/face"
fi

# The keyboard layout, pointer, touchpad and screens for the login screen's Hyprland, as
# key=value data the shell's Settings writes (HyprlandConfig.greeterData); its root-owned
# config (system/etc/greetd/hypr/hyprland.lua) checks every line. No Lua from here runs there:
# it ran as the greeter user (a copy of shell-settings.lua did until 2026-11-03).
if [ -f "$HOME/.config/hypr/greeter-settings" ]; then
    copy "$HOME/.config/hypr/greeter-settings" "$shared/greeter-settings"
fi
rm -f "$shared/shell-settings.lua"

# The lock screen's picture, from the shell (lock/LoginScreenSync.qml passes Wallpaper.lockPath;
# "" for none). Without an argument (modules/core/greeter.sh), the login screen keeps its picture until
# the shell runs this again at its next start.
[ $# -ge 1 ] || exit 0
picture=$1

if [ -n "$picture" ] && [ -f "$picture" ]; then
    target="$shared/picture.${picture##*.}"
    # The pictures can be large (tens of MB): only copy a different one.
    # Copied before the others go: a failed copy leaves the old picture and its wallpaper.json.
    if ! cmp -s "$picture" "$target"; then
        copy "$picture" "$target"
    fi
    printf '{ "path": "%s" }\n' "$target" > "$shared/wallpaper.json.tmp"
    mv -f "$shared/wallpaper.json.tmp" "$shared/wallpaper.json"
    for old in "$shared"/picture.*; do
        [ "$old" = "$target" ] || rm -f "$old"
    done
else
    # No picture: the login screen shows its plain background color.
    printf '{ "path": "" }\n' > "$shared/wallpaper.json.tmp"
    mv -f "$shared/wallpaper.json.tmp" "$shared/wallpaper.json"
    rm -f "$shared"/picture.*
fi
