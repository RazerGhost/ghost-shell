# The HP Omen 16-xf0 (board 8BCA): powered off with the RTX on, the next boot often had none
# (system/usr/local/lib/ghost-hp-8bca-rtx-off.sh says why); from the next power-off on, the
# service switches it off first.
if hw board 8BCA; then
    echo "HP Omen 16-xf0: the RTX off before a power-off"
    sudo install -Dm644 system/etc/systemd/system/ghost-hp-8bca-rtx-off.service /etc/systemd/system/ghost-hp-8bca-rtx-off.service
    sudo install -Dm755 system/usr/local/lib/ghost-hp-8bca-rtx-off.sh /usr/local/lib/ghost-hp-8bca-rtx-off.sh
    sudo systemctl daemon-reload
    # Started now too: it does nothing at start, and its stop step needs it running at shutdown.
    sudo systemctl enable --now ghost-hp-8bca-rtx-off.service
fi
