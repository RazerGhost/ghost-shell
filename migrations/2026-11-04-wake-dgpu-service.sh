# The service that woke the laptop's RTX at shutdown (2026-11-04) didn't help, and pointed the
# wrong way (docs/history.md "The RTX missing after a shutdown"): taken out where it was installed.
if [[ -e /etc/systemd/system/ghost-wake-dgpu.service ]]; then
    sudo systemctl disable --now ghost-wake-dgpu.service 2>/dev/null || true
    sudo rm /etc/systemd/system/ghost-wake-dgpu.service
    sudo systemctl daemon-reload
fi
