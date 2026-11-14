#!/usr/bin/env bash
# Undoes the claude module's setup: its rules and skills unlinked from ~/.claude (only the links
# into this module; your own files there stay). Run by `ghost remove claude`, and by
# `ghost install` when the setup failed.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

step "Claude Code: without the personal rules and skills"
here=$(cd "$(dirname "$0")" && pwd)
for link in "$HOME/.claude/CLAUDE.md" "$HOME"/.claude/skills/*; do
    if [[ -L $link && $(readlink "$link") == "$here"/* ]]; then rm "$link"; fi
done
