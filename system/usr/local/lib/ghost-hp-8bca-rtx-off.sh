#!/bin/bash
# The HP Omen 16-xf0 (board 8BCA): at a power-off (not a restart), switch the RTX fully off through
# its slot's firmware power switch (\_SB.PCI0.GPP0.PG00), the way Windows leaves it. Powered off
# with the card on, the next boot often has no RTX: the firmware's power-on skips setting up a card
# it finds enabled (ROADMAP: "The RTX missing after a shutdown"). Run by
# ghost-hp-8bca-rtx-off.service when it stops, after the sessions, PipeWire, the sound card state
# and Ollama have stopped. Takes the card and its HDMI sound device off the device list (nothing at
# shutdown can wake them then) and lets the slot power down. Never waits on a card still in use.
# Its lines are in the journal: journalctl -b -1 -t ghost-rtx-off
set -u
gpu=0000:01:00.0 audio=0000:01:00.1 port=0000:00:01.1
dev=/sys/bus/pci/devices
switch=$dev/$port/firmware_node/power_resources_D3hot

say() { logger -t ghost-rtx-off -- "$*"; }

# A power-off has a start job for poweroff.target (a restart has reboot.target's). Not found: left
# as it is, the safe way.
if ! systemctl list-jobs --no-legend 2>/dev/null | grep -q 'poweroff\.target.*start'; then
    say "Not a power-off: the RTX stays as it is."
    exit 0
fi
if [ ! -e "$dev/$gpu" ]; then
    say "The RTX isn't on the bus this boot: nothing to switch off."
    exit 0
fi
# The addresses are this laptop's; never remove anything that isn't NVIDIA's.
for d in "$gpu" "$audio"; do
    if [ -e "$dev/$d" ] && [ "$(cat "$dev/$d/vendor")" != 0x10de ]; then
        say "$d isn't an NVIDIA device: nothing done."
        exit 0
    fi
done

card=$(ls -d "$dev/$audio"/sound/card* 2>/dev/null | head -1)
card=${card##*/card}
# What can hold the card: CUDA (/dev/nvidia*), its display nodes (Hyprland draws through them) and
# its HDMI sound card.
files=(/dev/nvidia* /dev/dri/by-path/pci-$gpu-*)
[ -n "$card" ] && files+=(/dev/snd/*C"${card}"D* "/dev/snd/controlC$card")
if fuser -s "${files[@]}" 2>/dev/null; then
    # Taking away a sound card waits until every program has closed it: never hang a shutdown.
    say "Something still uses the RTX or its sound card, left on: $(fuser "${files[@]}" 2>&1 | tr -s ' \n' ' ')"
    exit 0
fi

[ -e "$dev/$audio" ] && echo 1 > "$dev/$audio/remove"
echo 1 > "$dev/$gpu/remove"
echo auto > "$dev/$port/power/control"
for _ in $(seq 1 50); do
    [ "$(cat "$switch"/*/resource_in_use 2>/dev/null)" = 0 ] && break
    sleep 0.2
done
say "Slot $(cat "$dev/$port/power_state"), power switch in use: $(cat "$switch"/*/resource_in_use 2>/dev/null)"
