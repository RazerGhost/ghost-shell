#!/usr/bin/env bash
# The desktop: links the configs (stow), GTK's look, the wallpaper folder and the colors.
# Usage: ghost install core [--theme <wallpaper | "#rrggbb">]
# Run by `ghost install`; alone: `ghost install core`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Linking configs with stow"
# Every top-level directory is a Stow package, except system/ (the system module installs it),
# tests/, modules/, docs/ and machines/.
# -R re-links, so files added to an already-stowed package get linked too.
# If stow reports a conflict, move the existing file aside and re-run.
# fish's folder exists first, so stow links the repo's files into it rather than the whole folder
# into the repo: fish writes its own files there (fish_variables, and config.fish's greeting line
# below), which would otherwise land in the repo.
mkdir -p "$HOME/.config/fish"
# zsh's .zshrc is the repo's: one written before (CachyOS's, which loads oh-my-zsh and
# Powerlevel10k) is moved aside once, so stow can link it.
if [[ -f $HOME/.zshrc && ! -L $HOME/.zshrc ]]; then
    mv "$HOME/.zshrc" "$HOME/.zshrc.pre-ghost"
    echo "Your earlier ~/.zshrc is now ~/.zshrc.pre-ghost (machine-local additions go in ~/.config/zsh/local.zsh)"
fi
for pkg in $(stow_packages); do
    echo "$pkg"
    stow -R -t "$HOME" "$pkg"
done
# Quickshell fills this in for the QML language server; it's gitignored.
touch quickshell/.config/quickshell/.qmlls.ini

step "Terminal greeting"
# fish (the fallback shell): its greeting (Settings -> Default apps) is ghost-greeting.fish, sourced from config.fish after
# CachyOS's config, which defines its own greeting (conf.d loads before config.fish, too early).
# config.fish stays yours: only this line is added, once.
greeting='source ~/.config/fish/ghost-greeting.fish'
mkdir -p "$HOME/.config/fish"
grep -qxF "$greeting" "$HOME/.config/fish/config.fish" 2>/dev/null \
    || printf '\n# Ghost Shell: the terminal greeting (Settings -> Default apps)\n%s\n' "$greeting" >>"$HOME/.config/fish/config.fish"

step "Login shell: zsh"
# User's choice (2026-11-05, was fish): bash-compatible, macOS's default. fish stays installed.
zsh_path=$(command -v zsh)
if [[ $(getent passwd "$USER" | cut -d: -f7) != "$zsh_path" ]]; then
    sudo chsh -s "$zsh_path" "$USER"
    echo "zsh is your login shell from the next login"
fi

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
