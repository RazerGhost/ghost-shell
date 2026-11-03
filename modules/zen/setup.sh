#!/usr/bin/env bash
# Zen: the wallpaper's colors through userChrome.css.
# Run by `ghost install`; alone: `ghost install zen`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Zen: the wallpaper's colors"
# matugen's hook (hooks/zen.sh) copies the colors into the profile as chrome/matugen.css on every
# wallpaper change; this imports that file from userChrome.css and lets Zen load userChrome.css.
# The profile Zen opens is Default= in installs.ini; it exists after Zen's first start.
zen="$HOME/.config/zen"
profile=$(sed -n 's/^Default=//p' "$zen/installs.ini" 2>/dev/null | head -n 1)
if [[ -z $profile || ! -d $zen/$profile ]]; then
    echo "Skipped: start Zen once, then run \`ghost install zen\`."
    exit 0
fi
chrome="$zen/$profile/chrome"
mkdir -p "$chrome"
# @import has to come before every other rule, so it goes on the first line.
if ! grep -qs '@import "matugen.css";' "$chrome/userChrome.css"; then
    { echo '@import "matugen.css";'; cat "$chrome/userChrome.css" 2>/dev/null || true; } > "$chrome/userChrome.css.tmp"
    mv "$chrome/userChrome.css.tmp" "$chrome/userChrome.css"
fi
pref='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
grep -qsF "$pref" "$zen/$profile/user.js" || echo "$pref" >> "$zen/$profile/user.js"
sh "$HOME/.config/matugen/hooks/zen.sh"
echo "Restart Zen to load the colors."
