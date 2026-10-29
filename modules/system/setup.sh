#!/usr/bin/env bash
# System setup for this laptop (needs sudo): the GPU udev rule and the RTX's power saving, early
# KMS and no Plymouth, greetd, one mDNS service, and the services the shell reads.
# Run by `ghost install`; alone: `ghost install system`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "GPU udev rule (stable /dev/dri/amd-igpu and /dev/dri/nvidia-dgpu)"
rule=system/etc/udev/rules.d/61-gpu-symlinks.rules
if ! cmp -s "$rule" "/etc/udev/rules.d/$(basename "$rule")"; then
    sudo install -Dm644 "$rule" "/etc/udev/rules.d/$(basename "$rule")"
    sudo udevadm control --reload
    sudo udevadm trigger --subsystem-match=drm
    udevadm settle
fi
# The iGPU is the primary GPU in AQ_DRM_DEVICES: without it Hyprland can't start, so stop here.
[[ -e /dev/dri/amd-igpu ]] || fail "/dev/dri/amd-igpu is missing (udev rule didn't match the AMD card)"
echo "amd-igpu    -> $(readlink -f /dev/dri/amd-igpu)"
# The RTX is only needed for outputs wired to it (HDMI / USB-C), so a missing card is a warning.
# It's missing when the NVIDIA driver didn't load or didn't create a DRM card.
if [[ -e /dev/dri/nvidia-dgpu ]]; then
    [[ $(readlink -f /dev/dri/nvidia-dgpu) != $(readlink -f /dev/dri/amd-igpu) ]] \
        || fail "both GPU symlinks point at $(readlink -f /dev/dri/amd-igpu)"
    echo "nvidia-dgpu -> $(readlink -f /dev/dri/nvidia-dgpu)"
else
    printf '\033[1;33mwarning:\033[0m /dev/dri/nvidia-dgpu is missing; external monitors on the RTX will not work.\n' >&2
    echo "NVIDIA driver status:"
    lspci -k -d 10de::03xx
    lsmod | grep -E '^nvidia' || echo "  (no nvidia kernel modules loaded)"
fi
echo "Compare with the PCI addresses below (1002 = AMD, 10de = NVIDIA):"
lspci -nn -d ::03xx
ls -l /dev/dri/by-path/ | grep -- '-card'

step "RTX power saving (takes effect after a reboot)"
# The driver reads modprobe.d when it loads (it isn't in the initramfs), so no rebuild.
power=system/etc/modprobe.d/50-nvidia-power.conf
if ! cmp -s "$power" "/etc/modprobe.d/$(basename "$power")"; then
    sudo install -Dm644 "$power" "/etc/modprobe.d/$(basename "$power")"
    echo "Reboot, then check: grep 'Runtime D3' /proc/driver/nvidia/gpus/*/power"
fi

step "Boot: early KMS, no Plymouth splash"
rebuild_boot=false

# Early KMS: load the AMD driver before any services start. CachyOS's chwd removes the kms
# hook on NVIDIA laptops (10-chwd-kms.conf), so without this amdgpu loads late.
kms=system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf
if ! cmp -s "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"; then
    sudo install -Dm644 "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"
    rebuild_boot=true
fi

# Plymouth leaves tty1 in graphics mode when it quits, so tuigreet draws to a console that
# shows nothing (black screen at boot). /etc/default/limine is bash; each
# KERNEL_CMDLINE[default]+= line appends to the kernel command line.
no_splash='KERNEL_CMDLINE[default]+=" plymouth.enable=0"'
if ! grep -qxF "$no_splash" /etc/default/limine; then
    echo "$no_splash" | sudo tee -a /etc/default/limine >/dev/null
    rebuild_boot=true
fi

# Plymouth is off, so its packages and initramfs hook go too.
noplymouth=system/etc/mkinitcpio.conf.d/30-no-plymouth.conf
if ! cmp -s "$noplymouth" "/etc/mkinitcpio.conf.d/$(basename "$noplymouth")"; then
    sudo install -Dm644 "$noplymouth" "/etc/mkinitcpio.conf.d/$(basename "$noplymouth")"
    rebuild_boot=true
fi
plymouth=$(pacman -Qq plymouth cachyos-plymouth-bootanimation cachyos-plymouth-theme 2>/dev/null || true)
if [[ -n $plymouth ]]; then
    # shellcheck disable=SC2086 # one package name per word
    sudo pacman -Rns --noconfirm $plymouth
    rebuild_boot=true
fi

if $rebuild_boot; then
    # limine-mkinitcpio (CachyOS) rebuilds the initramfs and rewrites the Limine boot entries.
    sudo limine-mkinitcpio
fi
# Stop if the option didn't reach the boot entries: greetd would boot to a black screen.
sudo grep -rqs --include=limine.conf 'plymouth.enable=0' /boot \
    || fail "plymouth.enable=0 is not in /boot's limine.conf; check /etc/default/limine and run sudo limine-mkinitcpio"

step "Login manager (greetd)"
sudo install -Dm644 system/etc/greetd/config.toml /etc/greetd/config.toml
sudo install -Dm644 system/etc/systemd/system/greetd.service.d/after-plymouth.conf \
    /etc/systemd/system/greetd.service.d/after-plymouth.conf
sudo systemctl daemon-reload
# Enable only, don't start: starting it now would take over tty1 under the running session.
# It takes effect on the next boot.
sudo systemctl enable greetd.service

step "Name lookup: one mDNS service (Avahi)"
mdns=system/etc/systemd/resolved.conf.d/50-no-mdns.conf
if ! cmp -s "$mdns" "/etc/systemd/resolved.conf.d/$(basename "$mdns")"; then
    sudo install -Dm644 "$mdns" "/etc/systemd/resolved.conf.d/$(basename "$mdns")"
    sudo systemctl try-restart systemd-resolved.service
fi

step "Services the Quickshell bar reads"
# Network, Bluetooth and power profile modules talk to these over D-Bus.
# UPower (battery) is started on demand by D-Bus, so it needs no enabling.
sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service
