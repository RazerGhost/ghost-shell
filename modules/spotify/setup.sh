#!/usr/bin/env bash
# Spotify: Spicetify with the Ghost theme, in the wallpaper's colors.
# Run by `ghost install`; alone: `ghost install spotify`. Safe to re-run. remove.sh undoes it.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Spotify: let Spicetify patch it"
# Spicetify rewrites files in /opt/spotify. Its docs make the folder writable for everyone;
# owning it as this user is enough.
sudo chown -R "$USER" /opt/spotify
# Spotify updates replace the patched files: pacman's hook patches the new version as the user
# who updated (modules/spotify/spicetify.sh after-update).
sudo install -Dm644 system/etc/pacman.d/hooks/ghost-spicetify.hook /etc/pacman.d/hooks/ghost-spicetify.hook
sudo install -Dm755 system/usr/local/lib/ghost-spicetify-after-update /usr/local/lib/ghost-spicetify-after-update

step "Spotify: the Ghost Spicetify theme"
# github.com/RazerGhost/spicetify-ghost. Its installer loads the theme from GitHub, so it
# updates itself. Spicetify needs Spotify's prefs file, which Spotify writes on first start.
if [[ -f $HOME/.config/spotify/prefs ]]; then
    # Spicetify patches from a backup of the original Spotify: made on the first run, and again
    # for a new Spotify version (reinstalling Spotify when Spicetify took its files out).
    bash modules/spotify/spicetify.sh patch
    curl -fsSL https://raw.githubusercontent.com/RazerGhost/spicetify-ghost/main/install.sh | sh
    # Ghost's installer just replaced its color.ini; put matugen's [matugen] scheme back in and
    # select it (matugen runs the same hook on every wallpaper change).
    sh "$HOME/.config/matugen/hooks/spicetify-ghost.sh"
else
    echo "Skipped: open Spotify once and log in, then run \`ghost install spotify\`."
fi
