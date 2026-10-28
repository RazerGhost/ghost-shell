#!/bin/sh
# Copies matugen's colors for Zen (templates/zen-colors.css) into Zen's profile as
# chrome/matugen.css. modules/zen/setup.sh imports it from userChrome.css. Nothing to do
# before Zen has made a profile (its first start).
zen="$HOME/.config/zen"
# The profile Zen opens: Default= in installs.ini (profiles.ini's Default= can be another one).
profile=$(sed -n 's/^Default=//p' "$zen/installs.ini" 2>/dev/null | head -n 1)
[ -n "$profile" ] && [ -d "$zen/$profile" ] || exit 0
mkdir -p "$zen/$profile/chrome"
cp "$HOME/.local/state/matugen/zen-colors.css" "$zen/$profile/chrome/matugen.css"
