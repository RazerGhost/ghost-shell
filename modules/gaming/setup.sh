#!/usr/bin/env bash
# Gaming: Millennium for Steam, and its Material-Theme in the wallpaper's colors.
# Run by `ghost install`; alone: `ghost install gaming`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Steam: Millennium"
# Millennium (themes and plugins for Steam) loads through a library Steam picks up from its own
# folder. Its package only links that for Steam folders that exist when it's installed, so
# link it here too. Steam creates the folder on its first start.
steam_dir="$HOME/.local/share/Steam"
if [[ -d $steam_dir/ubuntu12_64 ]]; then
    ln -sf /usr/lib/millennium/libmillennium_bootstrap_x86.so "$steam_dir/ubuntu12_32/libXtst.so.6"
    ln -sf /usr/lib/millennium/libmillennium_bootstrap_hhx64.so "$steam_dir/ubuntu12_64/libXtst.so.6"
else
    echo "Skipped: start Steam once, then run `ghost install gaming`."
fi

step "Steam: Material-Theme in the wallpaper's colors"
# github.com/kuska1/Material-Theme (MIT), a Millennium theme. Its Color option "Matugen" reads
# css/main/colors/matugen.css, which matugen fills (templates/steam-material.css and its hook).
# Millennium writes its settings on Steam's first start with it; until then, only the theme is
# put in place.
theme_dir="$HOME/.local/share/Steam/millennium/themes/Material-Theme"
if [[ -d $HOME/.local/share/Steam ]]; then
    mkdir -p "$(dirname "$theme_dir")"
    # The colors file is the theme's own, overwritten by matugen: undo that before pulling.
    [[ -d $theme_dir/.git ]] && git -C "$theme_dir" checkout -- css/main/colors/matugen.css
    # At a fixed commit: it has no releases, and its scripts run inside Steam (update: change the
    # commit after looking at what changed).
    clone_at https://github.com/kuska1/Material-Theme "$theme_dir" 32b6c127aab294c6f7c79ba7d3a12c717cc67227
    sh "$HOME/.config/matugen/hooks/steam-material.sh"
fi
millennium_config="$HOME/.config/millennium/config.json"
if [[ -f $millennium_config ]]; then
    # Select the theme with Color: Matugen, keeping your other Millennium settings.
    json_edit "$millennium_config" '
        data.themes ??= {};
        data.themes.activeTheme = "Material-Theme";
        data.themes.conditions ??= {};
        data.themes.conditions["Material-Theme"] ??= {};
        data.themes.conditions["Material-Theme"].Color = "Matugen";
    '
    echo "Restart Steam to load the theme."
else
    echo "Skipped selecting it: start Steam once (Millennium writes its settings), then run `ghost install gaming`."
fi
