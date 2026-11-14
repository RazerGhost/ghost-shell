#!/usr/bin/env bash
# Spicetify's patch of Spotify, kept in step with Spotify's version. Used by the spotify module's
# setup.sh and remove.sh, `ghost doctor`, and pacman's hook after a Spotify update
# (system/usr/local/lib/ghost-spicetify-after-update, which runs it as you):
#   spicetify.sh current       exits 0 when Spicetify's backup is of the installed Spotify
#   spicetify.sh patch         backs up and patches the installed Spotify, unless that's done
#   spicetify.sh after-update  the same without reinstalling Spotify (pacman's hook: pacman is busy)
#   spicetify.sh restore       Spotify as it came, Spicetify's backup cleared
#
# Spicetify patches Spotify from a backup of its original files. After a Spotify update the
# backup is of the old version and `spicetify apply` refuses; once it got halfway, deleting
# Spotify's own .spa files with no good backup of them: then only reinstalling Spotify brings them
# back (2026-11-14). `spicetify clear` only works on Spotify as it came.
set -euo pipefail

config=$HOME/.config/spicetify/config-xpui.ini

# A value from Spicetify's config: section, key (nothing when it isn't set).
setting() {
    [[ -f $config ]] || return 0
    awk -F' *= *' -v section="[$1]" -v key="$2" \
        '/^\[/ { in_section = ($0 == section) } in_section && $1 == key { print $2 }' "$config"
}

# Spotify's folder (the spotify package's, unless Spicetify was told another).
spotify_dir() {
    local dir
    dir=$(setting Setting spotify_path)
    dir=${dir:-/opt/spotify}
    echo "${dir%/}"
}

current() {
    local backup installed
    backup=$(setting Backup version)
    # Spicetify writes 1.3.8.620.g39b276d5d7ac; pacman has 1:1.3.8.620-1.
    installed=$(pacman -Q spotify | cut -d' ' -f2)
    installed=${installed#*:}
    installed=${installed%-*}
    [[ -n $backup && ${backup%.g*} == "$installed" ]]
}

# Spotify's own files back in place. Returns 1 when that needs reinstalling Spotify and $1 isn't
# "reinstall".
stock() {
    local missing dir app
    dir=$(spotify_dir)
    # Only the .spa files count: Spicetify also takes out a file nothing needs (native-licenses.html).
    missing=$(pacman -Qkq spotify 2>/dev/null | grep '\.spa$' || true)
    if [[ -n $missing ]]; then
        if [[ $1 != reinstall ]]; then
            echo "Spotify is missing its own files (Spicetify took them out); run \`ghost install spotify\`." >&2
            return 1
        fi
        echo "Spotify is missing its own files (Spicetify took them out): reinstalling Spotify."
        # GHOST_YES: `ghost install --yes` asks nothing.
        paru -S ${GHOST_YES:+--noconfirm --skipreview} spotify
        # Reinstalled files are root's; Spicetify writes into them.
        sudo chown -R "$USER" "$dir"
    fi
    # Folders Spicetify extracted from a .spa: next to Spotify's own .spa they're left from an
    # older patch.
    for app in "$dir"/Apps/*/; do
        app=${app%/}
        if [[ -f $app.spa ]]; then rm -rf "$app"; fi
    done
}

patch() {
    current && return 0
    stock "$1"
    # pacman's hook patches Spotify again after the reinstall (when it's installed).
    current && return 0
    spicetify -q clear
    spicetify backup apply
}

restore() {
    # Spicetify restores only from a backup of the installed Spotify. Without one, Spotify's own
    # files go back (pacman's hook may patch it again after a reinstall: then restore that).
    current || stock reinstall
    if current; then spicetify restore; fi
    stock reinstall
    spicetify -q clear
}

case ${1:-} in
    current) current ;;
    patch) patch reinstall ;;
    after-update)
        # Not where Spicetify never patched Spotify (or `ghost remove spotify` undid it).
        [[ -n $(setting Backup version) ]] || exit 0
        patch no-reinstall ;;
    restore) restore ;;
    *) echo "usage: $0 current | patch | after-update | restore" >&2; exit 2 ;;
esac
