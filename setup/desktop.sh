#!/usr/bin/env bash
# The desktop: links the configs (stow), GTK's look, the wallpaper folder and the colors.
# Usage: ./setup/desktop.sh [wallpaper | "#rrggbb"] (see install.sh).
# Part of install.sh; can also run on its own: ./setup/desktop.sh. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."
. setup/lib.sh

step "Linking configs with stow"
# Every top-level directory is a Stow package, except system/ (setup/system.sh installs it),
# tests/ and setup/.
# -R re-links, so files added to an already-stowed package get linked too.
# If stow reports a conflict, move the existing file aside and re-run.
for pkg in */; do
    pkg=${pkg%/}
    [[ $pkg == system || $pkg == tests || $pkg == setup ]] && continue
    echo "$pkg"
    stow -R -t "$HOME" "$pkg"
done
# Quickshell fills this in for the QML language server; it's gitignored.
touch quickshell/.config/quickshell/.qmlls.ini

step "GTK dark mode, theme and icons"
# adw-gtk3 makes GTK3 apps match libadwaita (GTK4) ones; GTK4 apps follow color-scheme.
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
# Colloid icons (user's choice); Quickshell gets the same theme from QS_ICON_THEME in env.lua.
gsettings set org.gnome.desktop.interface icon-theme Colloid-Dark
# Default apps (pictures, videos, music, browser, folders) are set by the shell at startup, from
# its settings (services/Apps.qml), so a re-run doesn't undo a choice made in Settings.
# Title bar buttons for apps that draw their own bar (GTK apps, Ghostty). No minimize: Hyprland
# ignores apps' minimize requests (Super+Down or the window menu minimizes instead).
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:maximize,close'

step "Wallpaper folder"
# The wallpaper picker (quick settings) shows the pictures in here.
mkdir -p "$HOME/Pictures/Wallpapers"

step "Colors (matugen)"
# The same script as the shell's wallpaper picker. With an image: it becomes the wallpaper and
# everything is colored from it; with "#rrggbb": colors from that seed; without either: colors
# again from the current wallpaper (or the default seed on the first run).
sh matugen/.config/matugen/wallpaper.sh "$@"
