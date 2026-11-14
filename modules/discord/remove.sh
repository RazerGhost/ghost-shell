#!/usr/bin/env bash
# Undoes the discord module's setup: Vesktop back on its own Vencord, the Ghost theme off. Run by
# `ghost remove discord`, and by `ghost install` when the setup failed. The Vencord and Ghost
# clones in ~/.local/share stay (nothing loads them now; the next setup builds from them).
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Discord: Vesktop's own Vencord"
state=$HOME/.config/vesktop/state.json
if [[ -f $state ]]; then json_edit "$state" 'delete data.vencordDir'; fi
settings=$HOME/.config/vesktop/settings/settings.json
if [[ -f $settings ]]; then
    json_edit "$settings" 'data.enabledThemes = (data.enabledThemes ?? []).filter(t => t !== "ghost-matugen.css")'
fi
echo "Restart Vesktop to load its own Vencord."
