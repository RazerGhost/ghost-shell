#!/usr/bin/env bash
# Development: Docker.
# Run by `ghost install`; alone: `ghost install dev`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Dev tools: Docker"
# docker.socket starts Docker on first use instead of at every boot.
sudo systemctl enable --now docker.socket
# The docker group lets you run docker without sudo. Membership is equivalent to root access
# (containers can mount /), so only your own user is added. It applies after logging in again.
id -nG "$USER" | grep -w docker >/dev/null || sudo usermod -aG docker "$USER"
