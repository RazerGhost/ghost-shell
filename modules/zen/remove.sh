#!/usr/bin/env bash
# Undoes the zen module's setup: userChrome.css no longer imports the wallpaper's colors. Run by
# `ghost remove zen`, and by `ghost install` when the setup failed. The userChrome.css pref stays
# on (other styles of yours may use it).
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Zen: without the wallpaper's colors"
zen="$HOME/.config/zen"
profile=$(sed -n 's/^Default=//p' "$zen/installs.ini" 2>/dev/null | head -n 1)
css=$zen/$profile/chrome/userChrome.css
if [[ -n $profile && -f $css ]]; then
    grep -vxF '@import "matugen.css";' "$css" >"$css.tmp" || true
    mv "$css.tmp" "$css"
    rm -f "$zen/$profile/chrome/matugen.css"
fi
