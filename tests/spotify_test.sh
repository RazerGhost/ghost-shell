#!/usr/bin/env bash
# Tests for modules/spotify/spicetify.sh (Spicetify's patch kept in step with Spotify's version):
# run from the repo root with `bash tests/spotify_test.sh`. A scratch Spotify folder and home, and
# stand-ins for pacman, paru, sudo and spicetify that act on them like the real ones (what
# Spicetify refuses included); nothing real is touched.
set -uo pipefail
cd "$(dirname "$0")/.."
script=$PWD/modules/spotify/spicetify.sh
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
bin=$scratch/bin
export HOME=$scratch/home LOG=$scratch/log SPOTIFY=$scratch/spotify SCRIPT=$script
mkdir -p "$bin" "$HOME/.config/spicetify"

# pacman: the installed version is $VERSION; -Qk lists the .spa files that are missing.
cat >"$bin/pacman" <<'STUB'
#!/bin/bash
case $1 in
    -Q) echo "spotify 1:$VERSION-1" ;;
    -Qkq) for f in "$SPOTIFY"/Apps/{login,xpui}.spa; do [[ -f $f ]] || { echo "spotify $f"; st=1; }; done; exit ${st:-0} ;;
esac
STUB
# paru: reinstalling Spotify puts its .spa files back; with HOOK set, pacman's hook runs after.
cat >"$bin/paru" <<'STUB'
#!/bin/bash
echo paru >>"$LOG"
touch "$SPOTIFY"/Apps/{login,xpui}.spa
[[ -z ${HOOK:-} ]] || bash "$SCRIPT" after-update
STUB
printf '#!/bin/sh\nexec "$@"\n' >"$bin/sudo"
# spicetify: its config holds the backup's version. Like the real one, clear and backup refuse
# without Spotify's own files, and backup apply extracts the .spa files and deletes them.
cat >"$bin/spicetify" <<'STUB'
#!/bin/bash
[[ $1 == -q ]] && shift
config=$HOME/.config/spicetify/config-xpui.ini
write() { printf '[Setting]\nspotify_path = %s/\n\n[Backup]\nversion = %s\n' "$SPOTIFY" "$1" >"$config"; }
stock() { [[ -f $SPOTIFY/Apps/xpui.spa ]]; }
echo "spicetify $*" >>"$LOG"
case $* in
    clear) stock && write "" ;;
    "backup apply")
        stock || { echo "Spotify cannot be backed up at this state" >&2; exit 1; }
        write "$VERSION.gabc123"
        for spa in "$SPOTIFY"/Apps/*.spa; do mkdir -p "${spa%.spa}"; rm "$spa"; done ;;
    restore) for dir in "$SPOTIFY"/Apps/*/; do touch "${dir%/}.spa"; rm -r "$dir"; done ;;
esac
STUB
chmod +x "$bin"/*
export PATH=$bin:$PATH

passed=0 failed=0
check() { # name, expected, got
    if [[ $3 == "$2" ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1: expected '$2', got '$3'"; fi
}
# A Spotify folder: version, backup's version, and what's in Apps (.spa files, extracted folders).
spotify() { # version backup_version apps...
    export VERSION=$1
    rm -rf "$SPOTIFY" && mkdir -p "$SPOTIFY/Apps"
    printf '[Setting]\nspotify_path = %s/\n\n[Backup]\nversion = %s\n' "$SPOTIFY" "$2" >"$HOME/.config/spicetify/config-xpui.ini"
    local app
    for app in "${@:3}"; do
        if [[ $app == *.spa ]]; then touch "$SPOTIFY/Apps/$app"; else mkdir "$SPOTIFY/Apps/$app"; fi
    done
    : >"$LOG"
}
run() { bash "$script" "$@" >/dev/null 2>&1; }
apps() { (cd "$SPOTIFY/Apps" && ls | tr '\n' ' ' | sed 's/ $//'); }
log() { tr '\n' ',' <"$LOG" | sed 's/,$//'; }

spotify 1.3.8.620 "" login.spa xpui.spa
run patch
check "first run: backed up and patched" "login xpui" "$(apps)"
run current
check "first run: current after" 0 "$?"
: >"$LOG"
run patch
check "patched already: nothing done" "" "$(log)"

# Spotify updated by pacman without the hook: its .spa files back, the old patch's folders beside.
spotify 1.3.9.100 1.3.8.620.gabc123 login.spa xpui.spa login xpui
run current
check "an update makes it not current" 1 "$?"
run patch
check "after an update: patched without reinstalling" "spicetify clear,spicetify backup apply" "$(log)"
check "after an update: the new files patched" "login xpui" "$(apps)"

# 2026-11-14: Spicetify deleted the .spa files with a backup of the old version.
spotify 1.3.8.620 1.3.4.258.gc60b10b0946a login xpui
run patch
check "files gone: Spotify reinstalled, then patched" "paru,spicetify clear,spicetify backup apply" "$(log)"
run current
check "files gone: current after" 0 "$?"

# The same with pacman's hook installed: it patches after the reinstall, and patch leaves it there.
spotify 1.3.8.620 1.3.4.258.gc60b10b0946a login xpui
HOOK=1 run patch
check "with the hook: patched once" "paru,spicetify clear,spicetify backup apply" "$(log)"

# pacman's hook: never reinstalls (pacman is busy), and does nothing where Spicetify never patched.
spotify 1.3.8.620 1.3.4.258.gc60b10b0946a login xpui
run after-update
check "hook with files gone: fails" 1 "$?"
check "hook with files gone: no reinstall" "" "$(log)"
spotify 1.3.8.620 "" login.spa xpui.spa
run after-update
check "hook where never patched: nothing" "" "$(log)"
spotify 1.3.9.100 1.3.8.620.gabc123 login.spa xpui.spa login xpui
run after-update
check "hook after an update: patched" "login xpui" "$(apps)"

# restore: Spotify as it came, the backup cleared.
spotify 1.3.8.620 1.3.8.620.gabc123 login xpui
run restore
check "restore: Spotify's own files" "login.spa xpui.spa" "$(apps)"
check "restore: backup cleared" 1 "$(grep -c 'version = $' "$HOME/.config/spicetify/config-xpui.ini")"
spotify 1.3.8.620 1.3.4.258.gc60b10b0946a login xpui
run restore
check "restore without a good backup: reinstalled, not spicetify's restore" "paru,spicetify clear" "$(log)"
check "restore without a good backup: Spotify's own files" "login.spa xpui.spa" "$(apps)"

echo "$passed passed, $failed failed"
((failed == 0))
