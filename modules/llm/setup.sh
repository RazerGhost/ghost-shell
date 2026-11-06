#!/usr/bin/env bash
# Local coding LLM on the RTX (needs sudo): Ollama's models on their own Btrfs subvolume, the
# Ollama service, and Aider. Run by `ghost install llm`. Safe to re-run.
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

models=/var/lib/ollama

step "Ollama: models kept out of the system snapshots"
# Snapshots of / don't include nested subvolumes, and models are several GB each. Turning the
# folder into one: copy it into a new subvolume (reflink copies share the data), then swap them.
if [[ $(findmnt -no FSTYPE /) != btrfs ]]; then
    echo "Skipped: / isn't Btrfs."
elif ! sudo btrfs subvolume show "$models" >/dev/null 2>&1; then
    was_active=false
    if systemctl is-active --quiet ollama; then
        was_active=true
        sudo systemctl stop ollama
    fi
    sudo mkdir -p "$models"
    sudo btrfs subvolume create "$models.new" >/dev/null
    sudo cp -a --reflink=auto "$models/." "$models.new/"
    sudo chown --reference="$models" "$models.new"
    sudo mv "$models" "$models.old"
    sudo mv "$models.new" "$models"
    sudo rm -rf "$models.old"
    if $was_active; then sudo systemctl start ollama; fi
fi

step "Ollama: the service, unloading models after 1 minute idle"
# The laptop's RTX can't power down fully (it idles at ~1.5 W), and a loaded model keeps it
# working harder. Ollama keeps a model in VRAM for 5 minutes after each use by default; an idle
# server with no model loaded holds no VRAM.
sudo install -Dm644 /dev/stdin /etc/systemd/system/ollama.service.d/keep-alive.conf <<'CONF'
[Service]
Environment=OLLAMA_KEEP_ALIVE=1m
CONF
sudo systemctl daemon-reload
sudo systemctl enable --now ollama

step "Aider"
# Through uv: it needs Python <3.13.
if uv tool list 2>/dev/null | grep '^aider-chat ' >/dev/null; then
    uv tool upgrade aider-chat
else
    uv tool install --python 3.12 aider-chat
fi
