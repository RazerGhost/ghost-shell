#!/usr/bin/env bash
# Tests for `ghost install` undoing a failed module and `ghost remove`: run from the repo root with
# `bash tests/modules_test.sh`. A scratch copy of ghost and lib.sh with made-up modules (under the
# real modules' names), stand-ins for sudo, pacman and paru that only log, and a scratch home.
set -uo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
repo=$scratch/repo bin=$scratch/bin
export HOME=$scratch/home XDG_STATE_HOME=$scratch/state LOG=$scratch/log
mkdir -p "$repo/bin/.local/bin" "$repo/migrations" "$bin" "$HOME"
cp bin/.local/bin/ghost bin/.local/bin/ghost-hw "$repo/bin/.local/bin/"
mkdir -p "$repo/modules" && cp modules/lib.sh "$repo/modules/"
echo 'true' >"$repo/migrations/2026-01-01-nothing.sh"
# sudo runs the command (the stand-ins below only log); pacman -Q knows what INSTALLED lists.
printf '#!/bin/sh\n[ "$1" = -v ] || [ "$1" = -n ] && exit 0\nexec "$@"\n' >"$bin/sudo"
cat >"$bin/pacman" <<'STUB'
#!/bin/bash
case $1 in
    -Qq) shift; for p; do grep -x "$p" <<<"$INSTALLED" || st=1; done; exit ${st:-0} ;;
    *) echo "pacman $*" >>"$LOG" ;;
esac
STUB
printf '#!/bin/sh\necho "paru $*" >>"$LOG"\n' >"$bin/paru"
printf '#!/bin/sh\nexit 0\n' >"$bin/rustup"
chmod +x "$bin"/*
export PATH=$bin:$PATH

passed=0 failed=0
check() { # name, expected, got
    if [[ $3 == "$2" ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1: expected '$2', got '$3'"; fi
}
module() { # name, setup's body, remove's body (none: no remove.sh), packages
    mkdir -p "$repo/modules/$1"
    echo "$2" >"$repo/modules/$1/setup.sh"
    if [[ -n $3 ]]; then echo "$3" >"$repo/modules/$1/remove.sh"; fi
    printf '%s\n' "${@:4}" >"$repo/modules/$1/packages.txt"
}
ghost() { "$repo/bin/.local/bin/ghost" "$@" >"$scratch/out" 2>&1; }
logged() { grep "$@" "$LOG" | tr '\n' ' ' | sed 's/ $//'; }

# install: a failing setup is undone, one that works isn't; the failure still fails the install.
# They run in ghost's order (discord spotify zen), whatever order they're named in.
module zen 'echo zen-setup >>"$LOG"; exit 1' 'echo zen-undo >>"$LOG"' zen-pkg
module spotify 'echo spotify-setup >>"$LOG"' 'echo spotify-undo >>"$LOG"' spotify shared-pkg
module discord 'exit 1' '' discord-pkg
ghost install zen spotify discord
check "a failed setup fails the install" 1 "$?"
check "the failed one is undone, the working one isn't" "spotify-setup zen-setup zen-undo" "$(logged -e '-setup' -e '-undo')"
check "the failures are named" 1 "$(grep -c 'setup failed.*: discord zen;' "$scratch/out")"

# remove: undoes the module, uninstalls only its installed packages nothing kept lists, and
# takes it off this machine's list.
: >"$LOG"
module core '' '' shared-pkg core-pkg
mkdir -p "$HOME/.config/ghost"
printf 'core\nspotify\nzen\n' >"$HOME/.config/ghost/modules"
INSTALLED=$'spotify\nshared-pkg' ghost remove spotify
check "remove succeeds" 0 "$?"
check "its remove.sh ran" "spotify-undo" "$(logged undo)"
check "only its own installed packages go" "pacman -Rnsu spotify" "$(logged pacman)"
check "off the machine's list" "core zen" "$(grep -v '^#' "$HOME/.config/ghost/modules" | tr '\n' ' ' | sed 's/ $//')"

# Without a machine list, the list is written out first (all modules but the removed one).
: >"$LOG"
rm "$HOME/.config/ghost/modules"
INSTALLED='' ghost remove --yes zen
check "a module without packages installed removes" 0 "$?"
check "no pacman without packages" "" "$(logged pacman)"
check "the list written without it" 0 "$(grep -cx zen "$HOME/.config/ghost/modules")"
check "the others stay on it" 1 "$(grep -cx spotify "$HOME/.config/ghost/modules")"

ghost remove core
check "core can't be removed" 1 "$?"
ghost remove nothing-like-it
check "an unknown module is refused" 1 "$?"

echo "$passed passed, $failed failed"
((failed == 0))
