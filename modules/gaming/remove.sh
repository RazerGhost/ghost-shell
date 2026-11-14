#!/usr/bin/env bash
# Undoes the gaming module's setup: Steam without Millennium (its libXtst links out of Steam's
# folders). Run by `ghost remove gaming`, and by `ghost install` when the setup failed. The
# Material-Theme folder and Millennium's settings stay; nothing loads them without Millennium.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Steam: without Millennium"
for link in "$HOME"/.local/share/Steam/ubuntu12_{32,64}/libXtst.so.6; do
    if [[ $(readlink "$link" 2>/dev/null) == /usr/lib/millennium/* ]]; then rm "$link"; fi
done
echo "Restart Steam to start it without Millennium."
