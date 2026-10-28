#!/usr/bin/env bash
# Spotify: Spicetify with the Ghost theme, in the wallpaper's colors.
# Run by `dots install`; alone: `dots install spotify`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Spotify: let Spicetify patch it"
# Spicetify rewrites files in /opt/spotify. Its docs make the folder writable for everyone;
# owning it as this user is enough. Spotify updates replace the files, so run
# `spicetify backup apply` after one.
sudo chown -R "$USER" /opt/spotify

step "Spotify: the Ghost Spicetify theme"
# github.com/RazerGhost/spicetify-ghost. Its installer loads the theme from GitHub, so it
# updates itself. Spicetify needs Spotify's prefs file, which Spotify writes on first start.
if [[ -f $HOME/.config/spotify/prefs ]]; then
    # Spicetify patches a backup of the original Spotify; the first run has to make it.
    # The [Backup] version in its config stays empty until then.
    if ! grep -A1 '^\[Backup\]' "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null | grep -q 'version *= *[0-9]'; then
        spicetify backup apply
    fi
    curl -fsSL https://raw.githubusercontent.com/RazerGhost/spicetify-ghost/main/install.sh | sh
    # Ghost's installer just replaced its color.ini; put matugen's [matugen] scheme back in and
    # select it (matugen runs the same hook on every wallpaper change).
    sh "$HOME/.config/matugen/hooks/spicetify-ghost.sh"
else
    echo "Skipped: open Spotify once and log in, then run `dots install spotify`."
fi
