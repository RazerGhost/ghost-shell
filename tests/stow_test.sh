#!/usr/bin/env bash
# Tests for stow_package in modules/lib.sh (whole folders only for the packages in
# folded_packages, the rest file by file): run from the repo root with `bash tests/stow_test.sh`.
# A scratch git repo with stand-in packages and a scratch home folder.
set -uo pipefail
cd "$(dirname "$0")/.."
lib=$PWD/modules/lib.sh
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
repo=$scratch/repo home=$scratch/home
mkdir -p "$repo/bin/.local/bin" "$repo/hypr/.config/hypr" "$home/.local" "$home/.config"
git -C "$repo" init -q
echo tool >"$repo/bin/.local/bin/ghost"
echo conf >"$repo/hypr/.config/hypr/hyprland.lua"
git -C "$repo" add -A
git -C "$repo" -c user.name=t -c user.email=t@t commit -qm init
passed=0 failed=0
check() { # name, expected, got
    if [[ $3 == "$2" ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1: expected '$2', got '$3'"; fi
}
link() { (cd "$repo" && HOME=$home bash -c '. "$1"; stow_package "$2"' _ "$lib" "$1"); }
kind() { if [[ -L $1 ]]; then echo link; elif [[ -d $1 ]]; then echo folder; elif [[ -f $1 ]]; then echo file; else echo none; fi; }

# An earlier version linked ~/.local/bin whole, and an installer then put a program into it.
(cd "$repo" && stow -t "$home" bin)
check "before: ~/.local/bin is the repo's folder" link "$(kind "$home/.local/bin")"
echo program >"$home/.local/bin/claude"
check "before: the program landed in the repo" file "$(kind "$repo/bin/.local/bin/claude")"
link bin
check "~/.local/bin is a real folder" folder "$(kind "$home/.local/bin")"
check "the repo's file is linked" link "$(kind "$home/.local/bin/ghost")"
check "the program moved out of the repo" file "$(kind "$home/.local/bin/claude")"
check "the program kept its content" program "$(cat "$home/.local/bin/claude")"
check "the repo has no stray files" "" "$(git -C "$repo" status --porcelain)"
link bin
check "again: nothing changes" folder "$(kind "$home/.local/bin")"

# hypr is in folded_packages: its folder stays one link.
link hypr
check "hypr: linked as a whole folder" link "$(kind "$home/.config/hypr")"

# ghost doctor's check: nothing left to link in simulation.
check "doctor sees bin linked" "" "$(cd "$repo" && HOME=$home bash -c '. "$1"; stow -n -v $(stow_flags bin) -t "$HOME" bin 2>&1 | grep -v "in simulation mode"' _ "$lib")"

echo "$passed passed, $failed failed"
((failed == 0))
