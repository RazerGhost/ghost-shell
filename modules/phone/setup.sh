#!/usr/bin/env bash
# The phone module: KDE Connect finds the phone over the local network on ports 1714-1764 (TCP
# and UDP). CachyOS turns on ufw, which refuses them by default, so the phone can't find the
# laptop; open them with the profile the kdeconnect package ships ("KDEConnect"). LocalSend finds
# devices and takes files on port 53317 (TCP and UDP).
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "KDE Connect and LocalSend through the firewall"
if systemctl is-active --quiet ufw; then
    sudo ufw allow KDEConnect
    sudo ufw allow 53317/tcp comment LocalSend
    sudo ufw allow 53317/udp comment LocalSend
else
    echo "ufw isn't running; nothing to open."
fi
