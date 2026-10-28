#!/bin/sh
# Copies matugen's colors for Steam (templates/steam-material.css) into Material-Theme, the
# Millennium theme the gaming module installs. The theme reads them every 1.5 s, so a running Steam
# recolors by itself. Nothing to do before the theme is installed.
theme="$HOME/.local/share/Steam/millennium/themes/Material-Theme"
[ -d "$theme" ] || exit 0
cp "$HOME/.local/state/matugen/steam-material.css" "$theme/css/main/colors/matugen.css"
