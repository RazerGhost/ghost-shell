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
# Packages go in as arguments, not on stdin: pacman and paru read their "Proceed?" prompts
# from stdin, and with the list piped in they'd get end-of-file instead of your answer.
mapfile -t pacman_pkgs < <(grep -v '^[[:space:]]*$' packages.txt)
mapfile -t aur_pkgs    < <(grep -v '^[[:space:]]*$' aur.txt)
sudo pacman -S --needed "${pacman_pkgs[@]}"
paru -S --needed "${aur_pkgs[@]}"

step "GPU udev rule (stable /dev/dri/amd-igpu and /dev/dri/nvidia-dgpu)"
rule=system/etc/udev/rules.d/61-gpu-symlinks.rules
if ! cmp -s "$rule" "/etc/udev/rules.d/$(basename "$rule")"; then
    sudo install -Dm644 "$rule" "/etc/udev/rules.d/$(basename "$rule")"
    sudo udevadm control --reload
    sudo udevadm trigger --subsystem-match=drm
    udevadm settle
fi
# The iGPU is the primary GPU in AQ_DRM_DEVICES: without it Hyprland can't start, so stop here.
[[ -e /dev/dri/amd-igpu ]] || fail "/dev/dri/amd-igpu is missing (udev rule didn't match the AMD card)"
echo "amd-igpu    -> $(readlink -f /dev/dri/amd-igpu)"
# The RTX is only needed for outputs wired to it (HDMI / USB-C), so a missing card is a warning.
# It's missing when the NVIDIA driver didn't load or didn't create a DRM card.
if [[ -e /dev/dri/nvidia-dgpu ]]; then
    [[ $(readlink -f /dev/dri/nvidia-dgpu) != $(readlink -f /dev/dri/amd-igpu) ]] \
        || fail "both GPU symlinks point at $(readlink -f /dev/dri/amd-igpu)"
    echo "nvidia-dgpu -> $(readlink -f /dev/dri/nvidia-dgpu)"
else
    printf '\033[1;33mwarning:\033[0m /dev/dri/nvidia-dgpu is missing; external monitors on the RTX will not work.\n' >&2
    echo "NVIDIA driver status:"
    lspci -k -d 10de::03xx
    lsmod | grep -E '^nvidia' || echo "  (no nvidia kernel modules loaded)"
fi
echo "Compare with the PCI addresses below (1002 = AMD, 10de = NVIDIA):"
lspci -nn -d ::03xx
ls -l /dev/dri/by-path/ | grep -- '-card'

step "Boot: early KMS, no Plymouth splash"
rebuild_boot=false

# Early KMS: load the AMD driver before any services start. CachyOS's chwd removes the kms
# hook on NVIDIA laptops (10-chwd-kms.conf), so without this amdgpu loads late.
kms=system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf
if ! cmp -s "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"; then
    sudo install -Dm644 "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"
    rebuild_boot=true
fi

# Plymouth leaves tty1 in graphics mode when it quits, so tuigreet draws to a console that
# shows nothing (black screen at boot). /etc/default/limine is bash; each
# KERNEL_CMDLINE[default]+= line appends to the kernel command line.
no_splash='KERNEL_CMDLINE[default]+=" plymouth.enable=0"'
if ! grep -qxF "$no_splash" /etc/default/limine; then
    echo "$no_splash" | sudo tee -a /etc/default/limine >/dev/null
    rebuild_boot=true
fi

if $rebuild_boot; then
    # limine-mkinitcpio (CachyOS) rebuilds the initramfs and rewrites the Limine boot entries.
    sudo limine-mkinitcpio
fi
# Stop if the option didn't reach the boot entries: greetd would boot to a black screen.
sudo grep -rqs --include=limine.conf 'plymouth.enable=0' /boot \
    || fail "plymouth.enable=0 is not in /boot's limine.conf; check /etc/default/limine and run sudo limine-mkinitcpio"

step "Login manager (greetd)"
sudo install -Dm644 system/etc/greetd/config.toml /etc/greetd/config.toml
sudo install -Dm644 system/etc/systemd/system/greetd.service.d/after-plymouth.conf \
    /etc/systemd/system/greetd.service.d/after-plymouth.conf
sudo systemctl daemon-reload
# Enable only, don't start: starting it now would take over tty1 under the running session.
# It takes effect on the next boot.
sudo systemctl enable greetd.service

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

step "GTK dark mode and theme"
# adw-gtk3 makes GTK3 apps match libadwaita (GTK4) ones; GTK4 apps follow color-scheme.
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark

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
