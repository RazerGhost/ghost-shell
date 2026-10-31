#!/usr/bin/env bash
# Aider through uv (it needs Python <3.13). The Ollama service, its settings and the @models
# subvolume are set up by ~/Projects/ghost-llm/scripts/install.sh.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

step "Aider"
if uv tool list 2>/dev/null | grep -q '^aider-chat '; then
    uv tool upgrade aider-chat
else
    uv tool install --python 3.12 aider-chat
fi
