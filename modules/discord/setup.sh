#!/usr/bin/env bash
# Discord (Vesktop): Vencord built with the Ghost theme plugin, in the wallpaper's colors.
# Run by `dots install`; alone: `dots install discord`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Discord: Vencord with the Ghost theme plugin, for Vesktop"
# Third-party Vencord plugins only load from a source build, so build Vencord with Ghost
# (github.com/RazerGhost/discord-ghost) as a userplugin and point Vesktop at that build.
# `dots install discord` again updates the plugin. Enable the plugin in Vesktop: Settings -> Plugins -> Ghost.
vencord_dir="$HOME/.local/share/vencord"
ghost_dir="$HOME/.local/share/discord-ghost"
# Vencord at a release (update: change the tag; github.com/Vendicated/Vencord/tags). Ghost is
# yours, so it follows its main branch.
clone_at https://github.com/Vendicated/Vencord "$vencord_dir" v1.15.13
clone_or_pull https://github.com/RazerGhost/discord-ghost "$ghost_dir"
(cd "$ghost_dir" && npm ci && node build.mjs --vencord "$vencord_dir")
(cd "$vencord_dir" && pnpm install --frozen-lockfile && pnpm build)
# Vesktop's "Vencord location" setting (Developer options) is vencordDir in state.json.
# Vesktop reads it at startup, so restart Vesktop after the first run.
VENCORD_DIST="$vencord_dir/dist" json_edit "$HOME/.config/vesktop/state.json" \
    'data.vencordDir = process.env.VENCORD_DIST'
# Vesktop and Vencord settings, merged so your other choices survive re-runs:
# - nativeTitleBar: Vesktop stops drawing Discord's minimize/maximize/close (Hyprland draws no
#   decorations; Super+drag moves the window).
# - the "Ghost matugen" theme on (matugen writes it, see templates/vesktop-ghost.css), and the
#   Ghost plugin's defaults on first run only: on, accent and colors from matugen, Hyprland's
#   rounding. Change them in Vesktop's settings afterwards.
json_edit "$HOME/.config/vesktop/settings.json" 'data.nativeTitleBar = true'
json_edit "$HOME/.config/vesktop/settings/settings.json" '
    data.enabledThemes = [...new Set([...(data.enabledThemes ?? []), "ghost-matugen.css"])];
    data.plugins ??= {};
    data.plugins.Ghost ??= { enabled: true, accentSource: "matugen", matugenColors: true, radius: 10, gap: 10 };
'
