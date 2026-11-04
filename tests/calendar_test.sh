#!/usr/bin/env bash
# Tests for modules/calendar/calendar.sh (ghost calendar add/remove): run from the repo root with
# `bash tests/calendar_test.sh`. Stand-ins for vdirsyncer, khal and the clipboard tools in a
# scratch home folder; nothing real is touched or downloaded.
set -uo pipefail
cd "$(dirname "$0")/.."
repo=$PWD
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
bin=$scratch/bin
mkdir -p "$bin"
passed=0 failed=0

# vdirsyncer: fails when VDIRSYNCER_FAILS is set, printing the address like aiohttp does.
cat >"$bin/vdirsyncer" <<'STUB'
#!/bin/sh
if [ -n "${VDIRSYNCER_FAILS:-}" ]; then
    url=$(grep -o 'https://[^"]*' "$HOME/.config/vdirsyncer/config" | head -1)
    echo "error: Unknown error occurred: 404, message='Not Found', url='$url'" >&2
    exit 1
fi
STUB
for tool in khal wl-copy cliphist; do printf '#!/bin/sh\nexit 0\n' >"$bin/$tool"; done
printf '#!/bin/sh\nexit 1\n' >"$bin/wl-paste" # an empty clipboard: the link is typed
chmod +x "$bin"/*

check() { # name, condition result
    if [ "$2" = 0 ]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1"; fi
}

run() { # link [name] -> output in $out, exit code in $code
    home=$scratch/home-$RANDOM
    mkdir -p "$home"
    out=$(printf '%s\n' "$1" | HOME=$home PATH="$bin:$PATH" "$repo/modules/calendar/calendar.sh" add "${2:-test}" 2>&1)
    code=$?
}

secret=https://calendar.example/ical/secret-token-123/basic.ics

VDIRSYNCER_FAILS=1 run "$secret"
check "a failing add exits with an error" "$([ $code -ne 0 ]; echo $?)"
check "a failing add leaves nothing behind" "$([ -z "$(find "$home" -type f)" ]; echo $?)"
check "the link never reaches the terminal" "$(! grep -q secret-token <<<"$out"; echo $?)"
check "vdirsyncer's message is shown with the link cut out" "$(grep -q '<link>' <<<"$out"; echo $?)"

run "$secret"
check "an add succeeds" "$([ $code -eq 0 ]; echo $?)"
check "the list is readable only by you" "$([ "$(stat -c %a "$home/.config/ghost/calendars")" = 600 ]; echo $?)"
check "vdirsyncer's config is readable only by you" "$([ "$(stat -c %a "$home/.config/vdirsyncer/config")" = 600 ]; echo $?)"
check "khal's config lists it" "$(grep -q '\[\[test\]\]' "$home/.config/khal/config"; echo $?)"
HOME=$home PATH="$bin:$PATH" modules/calendar/calendar.sh remove test >/dev/null
check "removing the last one removes the configs" "$([ ! -e "$home/.config/vdirsyncer/config" ] && [ ! -e "$home/.config/khal/config" ]; echo $?)"

run "webcal://calendar.example/x.ics" apple
check "a webcal link is taken as https" "$(grep -q 'https://calendar.example/x.ics' "$home/.config/ghost/calendars"; echo $?)"

run "http://calendar.example/x.ics"
check "a plain http link is refused" "$([ $code -ne 0 ] && [ ! -e "$home/.config/ghost/calendars" ]; echo $?)"

echo "$passed passed, $failed failed"
[ "$failed" = 0 ]
