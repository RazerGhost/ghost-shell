#!/usr/bin/env bash
# The desktop: links the configs (stow), GTK's look, the wallpaper folder and the colors.
# Usage: ghost install core [--theme <wallpaper | "#rrggbb">]
# Run by `ghost install`; alone: `ghost install core`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Linking configs with stow"
# Every top-level directory is a Stow package, except system/ (the system module installs it),
# tests/, modules/ and docs/.
# -R re-links, so files added to an already-stowed package get linked too.
# If stow reports a conflict, move the existing file aside and re-run.
for pkg in $(stow_packages); do
    echo "$pkg"
    stow -R -t "$HOME" "$pkg"
done
# Quickshell fills this in for the QML language server; it's gitignored.
touch quickshell/.config/quickshell/.qmlls.ini

step "GTK settings"
# Light or dark, the GTK theme (adw-gtk3) and the Colloid icons (user's choice) are set with the
# colors, by matugen's wallpaper.sh below, so they follow Settings -> Appearance. Quickshell gets
# its icons from QS_ICON_THEME in env.lua.
# Default apps (pictures, videos, music, browser, folders) are set by the shell at startup, from
# its settings (services/Apps.qml), so a re-run doesn't undo a choice made in Settings.
# Title bar buttons for apps that draw their own bar (GTK apps, Ghostty). No minimize: Hyprland
# (0.57) doesn't tell windows it can minimize (xdg-shell's wm_capabilities: only fullscreen and
# maximize), so GTK greys the button out. Super+Down or the window menu minimizes.
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:maximize,close'

step "Equalizer (PipeWire filter-chain)"
# Runs pipewire/.config/pipewire/filter-chain.conf.d/ghost-equalizer.conf; the shell sets its gains.
systemctl --user enable --now filter-chain.service

step "Wallpaper folder"
# The wallpaper picker (quick settings) shows the pictures in here.
mkdir -p "$HOME/Pictures/Wallpapers"

step "Colors (matugen)"
# The same script as the shell's wallpaper picker. With an image: it becomes the wallpaper and
# everything is colored from it; with "#rrggbb": colors from that seed; without either: colors
# again from the current wallpaper (or the default seed on the first run).
sh matugen/.config/matugen/wallpaper.sh "$@"
