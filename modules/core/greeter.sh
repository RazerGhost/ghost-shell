#!/usr/bin/env bash
# Sets up the Quickshell login screen. greetd runs it as the "greeter" user, which can't read
# your home folder, so this copies what it needs into place:
#   /etc/greetd/quickshell/   this repo's Quickshell config (greeter.qml is the entry point)
#   /etc/greetd/hypr/         the greeter's Hyprland config + your monitors, env and input
#   /var/lib/qs-greeter/      its home, with your user name
#   /var/lib/qs-greeter/shared/  yours: copies of your settings, colors and lock screen picture,
#                                which the shell keeps up to date (greeter/sync.sh)
# The core module runs it; `ghost greeter` runs it alone, which is needed after changing the
# shell's code (the login screen runs its own copy). Settings, colors and the wallpaper reach it
# by themselves.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

greeter_home=/var/lib/qs-greeter
greeter_state=$greeter_home/.local/state/quickshell

sudo rm -rf /etc/greetd/quickshell
sudo cp -r quickshell/.config/quickshell /etc/greetd/quickshell

sudo install -Dm644 system/etc/greetd/hypr/hyprland.lua /etc/greetd/hypr/hyprland.lua
# The keyboard layout from the settings window: greeter/sync.sh keeps the target up to date.
sudo ln -sfn /var/lib/qs-greeter/shared/shell-settings.lua /etc/greetd/hypr/shell-settings.lua
for file in monitors env input; do
    sudo install -Dm644 "hypr/.config/hypr/$file.lua" "/etc/greetd/hypr/$file.lua"
done

sudo install -d -o greeter -g greeter "$greeter_home" "$greeter_home/.local" \
    "$greeter_home/.local/state" "$greeter_state"
# The shared folder is yours, so the shell can update it without sudo; the greeter only reads
# it. Its files show up in the greeter's state folder (where the shell's services look) through
# symlinks. Older versions copied them there instead, and the wallpaper into the home folder.
sudo install -d -o "$USER" -g "$USER" -m755 "$greeter_home/shared"
for file in settings.json colors.json wallpaper.json; do
    sudo ln -sfn "$greeter_home/shared/$file" "$greeter_state/$file"
done
sudo rm -f "$greeter_home"/wallpaper.*
sh quickshell/.config/quickshell/greeter/sync.sh

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
GREETER_USER="$USER" json_edit "$tmp/greeter.json" 'data.user = process.env.GREETER_USER'
sudo install -m644 -o greeter -g greeter "$tmp/greeter.json" "$greeter_state/"
echo "Login screen updated for $USER."
