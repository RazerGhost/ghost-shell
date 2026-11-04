#!/usr/bin/env bash
# System setup for this laptop (needs sudo): the GPU udev rule, early KMS and the HP logo splash,
# Limine's boot menu, greetd (logging in at boot, then locking), one mDNS service, and the
# services the shell reads.
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

step "Boot: early KMS, the HP logo splash"
rebuild_boot=false

# Early KMS: load the AMD driver before any services start. CachyOS's chwd removes the kms
# hook on NVIDIA laptops (10-chwd-kms.conf), so without this amdgpu loads late.
kms=system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf
if ! cmp -s "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"; then
    sudo install -Dm644 "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"
    rebuild_boot=true
fi

# The boot splash (user's choice, 2026-11-04; off from 2026-10-28 until then): Plymouth's bgrt
# theme keeps the firmware's HP logo on screen with a spinner from when the graphics driver takes
# over (the screen went black there) until the session draws, and at shutdown. The plymouth
# package is in packages.txt; its hook is in /etc/mkinitcpio.conf's HOOKS (CachyOS's default).
# Until 2026-11-04 this module turned it off: undo that. /etc/default/limine is bash; each
# KERNEL_CMDLINE[default]+= line appends to the kernel command line.
if [[ -e /etc/mkinitcpio.conf.d/30-no-plymouth.conf ]]; then
    sudo rm /etc/mkinitcpio.conf.d/30-no-plymouth.conf
    rebuild_boot=true
fi
if grep -qF 'plymouth.enable=0' /etc/default/limine; then
    sudo sed -i '/plymouth\.enable=0/d' /etc/default/limine
    rebuild_boot=true
fi
grep -Eq '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf \
    || fail "/etc/mkinitcpio.conf's HOOKS has no plymouth; add it after kms"
splash='KERNEL_CMDLINE[default]+=" splash"'
if ! grep -qxF "$splash" /etc/default/limine; then
    echo "$splash" | sudo tee -a /etc/default/limine >/dev/null
    rebuild_boot=true
fi
if [[ $(plymouth-set-default-theme) != bgrt ]]; then
    sudo plymouth-set-default-theme bgrt
    rebuild_boot=true
fi
# Plymouth quits the normal way. With `quit --retain-splash` (installed here on 2026-11-04) it
# still held the graphics card when Hyprland started: logind refused it ("Device or resource
# busy"), Hyprland crashed and greetd started the session again a second later. Undo that.
if [[ -e /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf ]]; then
    sudo rm /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf
    sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/plymouth-quit.service.d
    sudo systemctl daemon-reload
fi

# A quiet console: tty1 shows before the desktop, and at logout and
# shutdown, so no kernel or boot messages below errors, no systemd status unless something is
# slow or fails, and no blinking text cursor (a recovery login on Ctrl+Alt+F2 has none either;
# `setterm --cursor on` brings it back there).
quiet_console='KERNEL_CMDLINE[default]+=" loglevel=3 rd.udev.log_level=3 systemd.show_status=auto vt.global_cursor_default=0"'
if ! grep -qxF "$quiet_console" /etc/default/limine; then
    echo "$quiet_console" | sudo tee -a /etc/default/limine >/dev/null
    rebuild_boot=true
fi

if $rebuild_boot; then
    # limine-mkinitcpio (CachyOS) rebuilds the initramfs and rewrites the Limine boot entries.
    sudo limine-mkinitcpio
fi
# Stop if the boot entries didn't follow: no splash, or still told to skip it. Only the
# kernels' own entries (two slashes deep, "//linux-cachyos"): the snapshot entries further down
# ("////linux-cachyos", limine-snapper-sync) keep the kernel line from when each was taken.
# /etc/default/limine is bash written for limine-entry-tool, which declares KERNEL_CMDLINE as a
# named (associative) array first; sourced bare, `[default]` is read as an unset variable under
# set -u.
esp=$(declare -A KERNEL_CMDLINE; . /etc/default/limine; echo "${ESP_PATH:-/boot}")
cmdlines=$(sudo awk '/^ *\//{ match($0, /\/+/); depth = RLENGTH } /cmdline:/ && depth == 2' "$esp/limine.conf")
[[ -n $cmdlines ]] || fail "no kernel entries in $esp/limine.conf; run sudo limine-mkinitcpio"
! grep -vqE ' splash( |$)' <<<"$cmdlines" \
    || fail "a kernel entry in $esp/limine.conf has no splash; check /etc/default/limine and run sudo limine-mkinitcpio"
! grep -qF 'plymouth.enable=0' <<<"$cmdlines" \
    || fail "a kernel entry in $esp/limine.conf still has plymouth.enable=0; check /etc/default/limine and run sudo limine-mkinitcpio"

step "Boot menu: the HP logo stays, the menu only on a key"
# Limine's own options, at the top of its config (limine-entry-tool, which rewrites the boot
# entries, keeps them): firmware_logo puts the firmware's logo back when Limine hands over
# (Plymouth then keeps it until Hyprland draws); quiet hides the menu unless a key is pressed during
# the timeout (to pick Windows or a snapshot). $esp is read in the step above.
limine_conf=$esp/limine.conf
sudo test -f "$limine_conf" || fail "$limine_conf is missing; check ESP_PATH in /etc/default/limine"
for option in "timeout: 1" "quiet: yes" "firmware_logo: yes"; do
    key=${option%%:*}
    if sudo grep -q "^$key:" "$limine_conf"; then
        sudo sed -i "s/^$key:.*/$option/" "$limine_conf"
    else
        sudo sed -i "1i $option" "$limine_conf"
    fi
done
# A config enrolled into Limine's binary must be enrolled again after a change, or it won't
# boot (off by default on CachyOS).
if grep -qs '^ENABLE_ENROLL_LIMINE_CONFIG=yes' /etc/default/limine /etc/limine-entry-tool.conf; then
    sudo limine-enroll-config
fi

step "Logging in (greetd)"
# Your user for the automatic login at boot and after a logout (config.toml's default_session):
# the session locks at once, there's no separate login screen.
sed "s/@USER@/$USER/" system/etc/greetd/config.toml >"${TMPDIR:-/tmp}/ghost-greetd.toml"
sudo install -Dm644 "${TMPDIR:-/tmp}/ghost-greetd.toml" /etc/greetd/config.toml
rm -f "${TMPDIR:-/tmp}/ghost-greetd.toml"
sudo install -Dm644 system/etc/systemd/system/greetd.service.d/after-plymouth.conf \
    /etc/systemd/system/greetd.service.d/after-plymouth.conf
sudo systemctl daemon-reload
# Enable only, don't start: starting it now would take over tty1 under the running session.
# It takes effect on the next boot.
sudo systemctl enable greetd.service
# The login screen that ran after a logout until 2026-11-04 (Quickshell as the greeter user):
# its copy of the shell, its Hyprland config and its home folder.
sudo rm -rf /etc/greetd/quickshell /etc/greetd/hypr /var/lib/qs-greeter

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
