#!/usr/bin/env bash
# Set up (or update) this machine from the dotfiles repo. Safe to re-run.
#
# Usage: ./install.sh [wallpaper | "#rrggbb"]
#   wallpaper  image to make the wallpaper and generate the colors from
#   #rrggbb    seed color to generate them from instead (quote it: # starts a comment)
#   Without either: colors again from the current wallpaper (a default seed on the first run).
#
# Each part is its own script in setup/ and can run alone, e.g. ./setup/steam.sh after Steam's
# first start. Run `git pull` before this script, not from it: pulling can change it mid-run.
set -euo pipefail

cd "$(dirname "$0")"
. setup/lib.sh

./setup/packages.sh
./setup/system.sh
./setup/desktop.sh "$@" # before the apps: they need the linked configs and the colors
./setup/discord.sh
./setup/spotify.sh
./setup/steam.sh
./setup/zen.sh

step "Login screen (Quickshell greeter)"
# After the colors, so the login screen gets the current ones. Settings, colors and the wallpaper
# reach it by themselves afterwards; re-run update-greeter.sh alone after changing the shell's code.
./update-greeter.sh

step "Done"
echo "Log out and back in if this was the first run or env.lua changed (GPU settings apply at Hyprland start)."
