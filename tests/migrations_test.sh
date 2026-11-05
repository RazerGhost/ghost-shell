#!/usr/bin/env bash
# Tests for `ghost migrate` (migrations/README.md): run from the repo root with
# `bash tests/migrations_test.sh`. A scratch copy of the repo's ghost, lib.sh and migrations, a
# stand-in sudo that only logs, and a scratch state folder.
set -uo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
repo=$scratch/repo
mkdir -p "$repo/bin/.local/bin" "$repo/modules" "$repo/migrations" "$scratch/bin" "$scratch/state"
cp bin/.local/bin/ghost bin/.local/bin/ghost-hw "$repo/bin/.local/bin/"
cp modules/lib.sh "$repo/modules/"
printf '#!/bin/sh\necho "sudo $*" >>"%s/sudo.log"\n' "$scratch" >"$scratch/bin/sudo"
chmod +x "$scratch/bin/sudo"
passed=0 failed=0
check() { # name, expected, got
    if [[ $3 == "$2" ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1: expected '$2', got '$3'"; fi
}
migrate() { PATH=$scratch/bin:$PATH XDG_STATE_HOME=$scratch/state "$repo/bin/.local/bin/ghost" migrate >/dev/null 2>&1; }
recorded() { tr '\n' ' ' <"$scratch/state/ghost/migrations" | sed 's/ $//'; }

echo 'echo a >>"$RUNS"' >"$repo/migrations/2026-01-01-a.sh"
echo 'echo b >>"$RUNS"' >"$repo/migrations/2026-01-02-b.sh"
export RUNS=$scratch/runs
migrate
check "both run, in name order" "a b" "$(tr '\n' ' ' <"$RUNS" | sed 's/ $//')"
check "both recorded" "2026-01-01-a 2026-01-02-b" "$(recorded)"
migrate
check "none runs twice" "a b" "$(tr '\n' ' ' <"$RUNS" | sed 's/ $//')"

# A failing one stops the run, isn't recorded, and the ones after it wait.
echo 'false' >"$repo/migrations/2026-01-03-broken.sh"
echo 'echo d >>"$RUNS"' >"$repo/migrations/2026-01-04-d.sh"
migrate
check "a failure fails" 1 "$?"
check "the failing one isn't recorded" "2026-01-01-a 2026-01-02-b" "$(recorded)"
check "the next one waits" "a b" "$(tr '\n' ' ' <"$RUNS" | sed 's/ $//')"
echo 'true' >"$repo/migrations/2026-01-03-broken.sh"
migrate
check "fixed, the rest run" "a b d" "$(tr '\n' ' ' <"$RUNS" | sed 's/ $//')"

# The repo's own migrations on a fresh machine (nothing they remove is there): each one succeeds
# without touching anything.
rm -f "$repo"/migrations/* "$scratch/sudo.log" "$scratch/state/ghost/migrations"
cp migrations/*.sh "$repo/migrations/"
migrate
check "the repo's migrations all recorded" "$(ls migrations/*.sh | wc -l)" "$(wc -l <"$scratch/state/ghost/migrations")"
check "nothing removed on a fresh machine" "sudo -v" "$(grep -v -- '-n -v' "$scratch/sudo.log" 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/ $//')"

echo "$passed passed, $failed failed"
((failed == 0))
