#!/usr/bin/env bash
# A fresh machine in one command (Arch or CachyOS). The repo is private, so through GitHub's CLI,
# logged in once (`sudo pacman -S github-cli` and `gh auth login`):
#   bash <(gh api repos/RazerGhost/ghost-shell/contents/bootstrap.sh -H "Accept: application/vnd.github.raw") desktop
# Installs git if it's missing, clones the repo to ~/Projects/ghost-shell (or pulls it if it's
# there and has no uncommitted changes), then runs install.sh with the same arguments: a machine
# profile (machines/: laptop, desktop), a wallpaper or "#rrggbb", --yes.
set -euo pipefail
repo=$HOME/Projects/ghost-shell
command -v git >/dev/null || sudo pacman -S --needed git
if [[ -d $repo/.git ]]; then
    if [[ -n $(git -C "$repo" status --porcelain) ]]; then
        echo "$repo has uncommitted changes: using it as it is" >&2
    else
        git -C "$repo" pull --ff-only
    fi
else
    mkdir -p "$(dirname "$repo")"
    if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
        gh repo clone RazerGhost/ghost-shell "$repo"
    else
        git clone https://github.com/RazerGhost/ghost-shell "$repo" # asks for your GitHub login
    fi
fi
exec "$repo/install.sh" "$@"
