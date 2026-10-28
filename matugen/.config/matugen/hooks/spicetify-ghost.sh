#!/bin/sh
# Puts matugen's Spotify colors into the Ghost Spicetify theme and switches Spotify to them.
# Run by matugen after it renders templates/spicetify-ghost.ini, and by the spotify module's setup after it
# (re)installs Ghost, whose installer replaces color.ini with the theme's own schemes.
# Does nothing until Spicetify and Ghost are set up.

scheme="$HOME/.local/state/matugen/spicetify-ghost.ini"
command -v spicetify >/dev/null 2>&1 || exit 0
ini="$(spicetify path userdata 2>/dev/null)/Themes/Ghost/color.ini"
[ -f "$scheme" ] && [ -f "$ini" ] || exit 0

# Drop the previous [matugen] section (from its header to the next one), then append the new one.
awk '/^\[/ { skip = ($0 == "[matugen]") } !skip' "$ini" > "$ini.tmp"
cat "$scheme" >> "$ini.tmp" && mv "$ini.tmp" "$ini"

# refresh rewrites the theme's colors in Spotify's files without a full apply; open Spotify
# windows show them after a restart.
spicetify config color_scheme matugen >/dev/null 2>&1
spicetify refresh >/dev/null 2>&1 || true
