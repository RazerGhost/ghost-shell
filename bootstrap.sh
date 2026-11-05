#!/usr/bin/env bash
# A fresh machine in one command (Arch or CachyOS), in zsh, fish or bash:
#   curl -fsSL https://raw.githubusercontent.com/RazerGhost/ghost-shell/main/bootstrap.sh -o /tmp/bootstrap.sh && bash /tmp/bootstrap.sh desktop
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
    git clone https://github.com/RazerGhost/ghost-shell "$repo"
fi
exec "$repo/install.sh" "$@"
