#!/usr/bin/env bash
# First-time setup from the dotfiles repo (afterwards, `ghost install` or `ghost update` does the
# same). Runs bin/.local/bin/ghost from the repo, since it isn't linked into ~/.local/bin yet.
#
# Usage: ./install.sh [wallpaper | "#rrggbb"]
#   wallpaper  image to make the wallpaper and generate the colors from
#   #rrggbb    seed color to generate them from instead (quote it: # starts a comment)
#   Without either: colors again from the current wallpaper (a default seed on the first run).
#
# It sets up this machine's modules (all of them unless ~/.config/ghost/modules lists some; see
# `ghost help`). Run `git pull` before this script, not from it: pulling can change it mid-run.
set -euo pipefail
cd "$(dirname "$0")"
if (($#)); then
    exec ./bin/.local/bin/ghost install --theme "$1"
fi
exec ./bin/.local/bin/ghost install
