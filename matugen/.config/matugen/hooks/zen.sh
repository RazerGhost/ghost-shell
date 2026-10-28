#!/bin/sh
# Puts matugen's colors for Zen (templates/zen-colors.css) into Zen's profile: copied as
# chrome/matugen.css, imported from chrome/userChrome.css, and the pref that lets Zen load
# userChrome.css turned on in user.js. Safe to run again; nothing to do before Zen has made a
# profile (its first start).
zen="$HOME/.config/zen"
# The profile Zen opens: Default= in installs.ini (profiles.ini's Default= can be another one).
profile=$(sed -n 's/^Default=//p' "$zen/installs.ini" 2>/dev/null | head -n 1)
[ -n "$profile" ] && [ -d "$zen/$profile" ] || exit 0
chrome="$zen/$profile/chrome"
mkdir -p "$chrome"
cp "$HOME/.local/state/matugen/zen-colors.css" "$chrome/matugen.css"

# @import has to come before every other rule, so it goes on the first line.
if ! grep -qs '@import "matugen.css";' "$chrome/userChrome.css"; then
    { echo '@import "matugen.css";'; cat "$chrome/userChrome.css" 2>/dev/null; } > "$chrome/userChrome.css.tmp"
    mv "$chrome/userChrome.css.tmp" "$chrome/userChrome.css"
fi

pref='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
grep -qsF "$pref" "$zen/$profile/user.js" || echo "$pref" >> "$zen/$profile/user.js"
