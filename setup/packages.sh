#!/usr/bin/env bash
# Installs the packages in packages.txt (pacman) and aur.txt (paru).
# Part of install.sh; can also run on its own: ./setup/packages.sh. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."
. setup/lib.sh

step "Installing packages (packages.txt, aur.txt)"
# steam comes from [multilib]; CachyOS enables it in /etc/pacman.conf by default.
# Packages go in as arguments, not on stdin: pacman and paru read their "Proceed?" prompts
# from stdin, and with the list piped in they'd get end-of-file instead of your answer.
mapfile -t pacman_pkgs < <(grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' packages.txt)
mapfile -t aur_pkgs    < <(grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' aur.txt)
sudo pacman -S --needed "${pacman_pkgs[@]}"
# rustup installs no toolchain by itself. Set up stable before the AUR packages: some build
# with Rust (millennium), and so does Haunt (Tauri).
rustup toolchain list | grep -q stable || rustup default stable
paru -S --needed "${aur_pkgs[@]}"
