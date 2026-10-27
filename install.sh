#!/usr/bin/env bash
# Set up (or update) this machine from the dotfiles repo. Safe to re-run.
#
# Usage: ./install.sh [wallpaper | "#rrggbb"]
#   wallpaper  image to generate matugen colors from
#   #rrggbb    seed color to generate them from instead (quote it: # starts a comment)
#   Without either, the first run uses a default seed color.
#
# Run `git pull` before this script, not from it: pulling can change this file mid-run.
set -euo pipefail

cd "$(dirname "$0")"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

step "Installing packages (packages.txt, aur.txt)"
sudo pacman -S --needed - < packages.txt
paru -S --needed - < aur.txt

step "GPU udev rule (stable /dev/dri/amd-igpu and /dev/dri/nvidia-dgpu)"
rule=system/etc/udev/rules.d/61-gpu-symlinks.rules
if ! cmp -s "$rule" "/etc/udev/rules.d/$(basename "$rule")"; then
    sudo install -Dm644 "$rule" "/etc/udev/rules.d/$(basename "$rule")"
    sudo udevadm control --reload
    sudo udevadm trigger --subsystem-match=drm
    udevadm settle
fi
# Hyprland won't start if these are missing or point at the same card, so stop here instead.
[[ -e /dev/dri/amd-igpu ]]    || fail "/dev/dri/amd-igpu is missing (udev rule didn't match the AMD card)"
[[ -e /dev/dri/nvidia-dgpu ]] || fail "/dev/dri/nvidia-dgpu is missing (udev rule didn't match the NVIDIA card)"
igpu=$(readlink -f /dev/dri/amd-igpu)
dgpu=$(readlink -f /dev/dri/nvidia-dgpu)
[[ $igpu != "$dgpu" ]] || fail "both GPU symlinks point at $igpu"
echo "amd-igpu    -> $igpu"
echo "nvidia-dgpu -> $dgpu"
echo "Compare with the PCI addresses below (1002 = AMD, 10de = NVIDIA):"
lspci -nn -d ::03xx
ls -l /dev/dri/by-path/ | grep -- '-card'

step "Linking configs with stow"
# Every top-level directory is a Stow package, except system/ (installed above).
# -R re-links, so files added to an already-stowed package get linked too.
# If stow reports a conflict, move the existing file aside and re-run.
for pkg in */; do
    pkg=${pkg%/}
    [[ $pkg == system ]] && continue
    echo "$pkg"
    stow -R -t "$HOME" "$pkg"
done
# Quickshell fills this in for the QML language server; it's gitignored.
touch quickshell/.config/quickshell/.qmlls.ini

step "Generating colors with matugen"
# Without a wallpaper, matugen builds the scheme from one seed color.
# #6750a4 is the Material baseline purple, the same scheme as the fallbacks in Colors.qml.
default_seed="#6750a4"
if [[ $# -ge 1 && $1 == \#* ]]; then
    matugen color hex "$1" -m dark
elif [[ $# -ge 1 ]]; then
    [[ -f $1 ]] || fail "wallpaper not found: $1"
    matugen image "$1" -m dark --source-color-index 0
elif [[ -f $HOME/.local/state/quickshell/colors.json ]]; then
    echo "Colors already generated; pass a wallpaper or a hex color to regenerate."
else
    echo "No wallpaper given, using seed color $default_seed"
    matugen color hex "$default_seed" -m dark
fi

step "Done"
echo "Log out and back in if this was the first run or env.lua changed (GPU settings apply at Hyprland start)."
