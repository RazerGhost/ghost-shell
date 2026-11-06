#!/usr/bin/env bash
# Claude Code's personal rules and skills for every project (modules/claude/CLAUDE.md, skills/),
# linked into ~/.claude. A repo's own CLAUDE.md sits on top of them. Safe to re-run.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

step "Claude Code: personal rules and skills"
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$HOME/.claude/skills"
ln -sfn "$here/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
for skill in "$here"/skills/*/; do
    ln -sfn "${skill%/}" "$HOME/.claude/skills/$(basename "$skill")"
done
