#!/usr/bin/env bash
# Tests for bin/.local/bin/ghost-greeting (the terminal greeting for zsh and fish): run from the
# repo root with `bash tests/greeting_test.sh`. A stand-in fastfetch and settings in a scratch
# home folder.
set -uo pipefail
cd "$(dirname "$0")/.."
greeting=$PWD/bin/.local/bin/ghost-greeting
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/state/quickshell"
printf '#!/bin/sh\necho FASTFETCH\n' >"$scratch/bin/fastfetch"
chmod +x "$scratch/bin/fastfetch"
passed=0 failed=0
check() { # name, expected pattern, output
    if [[ $3 =~ $2 ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1: got '$3'"; fi
}
run() { XDG_STATE_HOME=$scratch/state PATH=$scratch/bin:$PATH "$greeting"; }
settings=$scratch/state/quickshell/settings.json

check "no settings: the system summary" '^FASTFETCH$' "$(run)"
echo '{"terminalGreeting": "none", "x": 1}' >"$settings"
check "none: nothing" '^$' "$(run)"
echo '{"a":{"b":2},"terminalGreeting":"line"}' >"$settings"
check "line: one line" '^.*Good (morning|afternoon|evening), [^ ]+.* · .+ · up [0-9]+ min' "$(run)"
check "line: one line only" '^1$' "$(run | wc -l)"
echo '{"terminalGreeting":"ghost"}' >"$settings"
check "ghost: the system summary" '^FASTFETCH$' "$(run)"
echo '{"other":"line"}' >"$settings"
check "no greeting setting: the system summary" '^FASTFETCH$' "$(run)"

echo "$passed passed, $failed failed"
((failed == 0))
