#!/usr/bin/env bash
# First-time setup from the dotfiles repo (afterwards, `ghost install` or `ghost update` does the
# same). Runs bin/.local/bin/ghost from the repo, since it isn't linked into ~/.local/bin yet.
#
# Usage: ./install.sh [machine] [wallpaper | "#rrggbb"] [--yes]
#   machine    a profile from machines/ (laptop, desktop): which modules this machine gets
#   wallpaper  image to make the wallpaper and generate the colors from
#   #rrggbb    seed color to generate them from instead (quote it: # starts a comment)
#   --yes      no questions from pacman and paru (paru then skips showing the PKGBUILDs)
#   Without a machine: this machine's modules (~/.config/ghost/modules, or all of them but the
#   opt-in ones). Without a wallpaper: colors again from the current one (a default seed at first).
#
# Run `git pull` before this script, not from it: pulling can change it mid-run. bootstrap.sh
# clones the repo and runs this in one go.
set -euo pipefail
cd "$(dirname "$0")"
args=()
for arg in "$@"; do
    if [[ $arg == --yes ]]; then
        args+=(--yes)
    elif [[ $arg != */* && -f machines/$arg ]]; then
        args+=(--machine "$arg")
    elif [[ -f $arg || $arg =~ ^#[0-9a-fA-F]{6}$ ]]; then
        args+=(--theme "$arg")
    else
        # A mistyped machine name would otherwise be taken as a wallpaper and install every module.
        echo "install.sh: '$arg' is no machine profile (machines/: $(ls machines | tr '\n' ' '))," >&2
        echo "a picture that exists, or a #rrggbb color" >&2
        exit 1
    fi
done
exec ./bin/.local/bin/ghost install "${args[@]}"
