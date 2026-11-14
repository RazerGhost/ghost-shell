#!/usr/bin/env bash
# Undoes the phone module's setup: KDE Connect's tray no longer starts with Hyprland, and the
# firewall closes its and LocalSend's ports again. Run by `ghost remove phone`, and by
# `ghost install` when the setup failed.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "KDE Connect and LocalSend: not started, ports closed"
rm -f "$HOME/.config/hypr/autostart.d/phone.lua"
if systemctl is-active --quiet ufw; then
    sudo ufw delete allow KDEConnect
    sudo ufw delete allow 53317/tcp
    sudo ufw delete allow 53317/udp
fi
