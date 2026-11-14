#!/usr/bin/env bash
# Undoes the spotify module's setup: Spotify as it came, without Spicetify's patch, the theme or
# pacman's hook. Run by `ghost remove spotify`, and by `ghost install` when the setup failed (a
# half-patched Spotify doesn't start; the plain one does).
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Spotify: without Spicetify"
if command -v spicetify >/dev/null && pacman -Q spotify >/dev/null 2>&1; then
    bash modules/spotify/spicetify.sh restore
fi
sudo rm -f /etc/pacman.d/hooks/ghost-spicetify.hook /usr/local/lib/ghost-spicetify-after-update
if [[ -d /opt/spotify ]]; then sudo chown -R root:root /opt/spotify; fi
