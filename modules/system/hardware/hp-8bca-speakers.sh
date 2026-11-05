# The HP Omen 16-xf0 (board 8BCA): the kernel leaves its bass speakers off. The patch file
# (system/usr/lib/firmware/ghost-hp-8bca-speakers.fw) says why; it takes effect when the sound
# driver loads next, at the next boot.
if hw board 8BCA; then
    echo "HP Omen 16-xf0: its bass speakers"
    sudo install -Dm644 system/usr/lib/firmware/ghost-hp-8bca-speakers.fw /usr/lib/firmware/ghost-hp-8bca-speakers.fw
    sudo install -Dm644 system/etc/modprobe.d/ghost-hp-8bca-speakers.conf /etc/modprobe.d/ghost-hp-8bca-speakers.conf
fi
