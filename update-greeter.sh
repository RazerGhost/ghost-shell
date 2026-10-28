#!/usr/bin/env bash
# Sets up the Quickshell login screen. greetd runs it as the "greeter" user, which can't read
# your home folder, so this copies what it needs into place:
#   /etc/greetd/quickshell/   this repo's Quickshell config (greeter.qml is the entry point)
#   /etc/greetd/hypr/         the greeter's Hyprland config + your monitors, env and input
#   /var/lib/qs-greeter/      its home: a snapshot of your colors and wallpaper, and your name
# install.sh runs it. Run it again after changing your wallpaper or colors to update the login
# screen's look.
set -euo pipefail
cd "$(dirname "$0")"

state="$HOME/.local/state/quickshell"
greeter_home=/var/lib/qs-greeter
greeter_state=$greeter_home/.local/state/quickshell

sudo rm -rf /etc/greetd/quickshell
sudo cp -r quickshell/.config/quickshell /etc/greetd/quickshell

sudo install -Dm644 system/etc/greetd/hypr/hyprland.lua /etc/greetd/hypr/hyprland.lua
for file in monitors env input; do
    sudo install -Dm644 "hypr/.config/hypr/$file.lua" "/etc/greetd/hypr/$file.lua"
done

sudo install -d -o greeter -g greeter "$greeter_home" "$greeter_home/.local" \
    "$greeter_home/.local/state" "$greeter_state"
if [[ -f $state/colors.json ]]; then
    sudo install -m644 -o greeter -g greeter "$state/colors.json" "$greeter_state/colors.json"
fi

# The wallpaper: copy the picture itself (its path is in your home) and point the copy at it.
wallpaper=$(node -e 'try { process.stdout.write(require(process.argv[1]).path || "") } catch {}' \
    "$state/wallpaper.json")
greeter_wallpaper=""
if [[ -n $wallpaper && -f $wallpaper ]]; then
    greeter_wallpaper="$greeter_home/wallpaper.${wallpaper##*.}"
    sudo install -m644 -o greeter -g greeter "$wallpaper" "$greeter_wallpaper"
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
WALLPAPER="$greeter_wallpaper" GREETER_USER="$USER" TMP="$tmp" node -e '
    const fs = require("fs");
    const write = (name, data) => fs.writeFileSync(process.env.TMP + "/" + name, JSON.stringify(data, null, 4) + "\n");
    write("wallpaper.json", { path: process.env.WALLPAPER });
    write("greeter.json", { user: process.env.GREETER_USER });
'
sudo install -m644 -o greeter -g greeter "$tmp/wallpaper.json" "$tmp/greeter.json" "$greeter_state/"
echo "Login screen updated for $USER."
