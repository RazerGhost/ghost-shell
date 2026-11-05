#!/usr/bin/env bash
# System setup (needs sudo): the GPU udev rule, early KMS and no Plymouth,
# Limine's boot menu, greetd (logging in at boot, then locking), one mDNS service, and the
# services the shell reads.
# Run by `ghost install`; alone: `ghost install system`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "GPUs: a stable link for each (/dev/dri/gpu-pci-<slot>)"
rule=system/etc/udev/rules.d/61-gpu-symlinks.rules
if ! cmp -s "$rule" "/etc/udev/rules.d/$(basename "$rule")"; then
    sudo install -Dm644 "$rule" "/etc/udev/rules.d/$(basename "$rule")"
    sudo udevadm control --reload
    sudo udevadm trigger --subsystem-match=drm
    udevadm settle
fi
# What ghost-hw found: the display GPU goes first in Hyprland's AQ_DRM_DEVICES (env.lua).
hw facts
hw drm-devices >/dev/null || fail "no /dev/dri/gpu-pci-* links; check $rule against udevadm info /dev/dri/card*"
no_driver=$(hw facts | sed -n 's/^no_driver=//p')
if [[ -n $no_driver ]]; then
    # A card without a driver: screens wired to it won't work (an RTX whose NVIDIA module didn't load).
    printf '\033[1;33mwarning:\033[0m no driver for %s; screens on it will not work.\n' "$no_driver" >&2
    lsmod | grep -E '^nvidia' || echo "  (no nvidia kernel modules loaded)"
fi

step "Boot: early KMS, no Plymouth splash"
rebuild_boot=false
# The kernel line and the boot menu are set for Limine (CachyOS's default); with another boot
# loader those parts are skipped and say so.
limine=false
[[ -f /etc/default/limine ]] && command -v limine-mkinitcpio >/dev/null && limine=true

# Early KMS: load the AMD driver before any services start where it drives the display. CachyOS's
# chwd removes the kms hook on NVIDIA laptops (10-chwd-kms.conf), so without this amdgpu loads late.
kms=system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf
if [[ $(hw display-gpu) == amd ]] && ! cmp -s "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"; then
    sudo install -Dm644 "$kms" "/etc/mkinitcpio.conf.d/$(basename "$kms")"
    rebuild_boot=true
fi

# No boot splash (user's choice; tried again on 2026-11-04 with the HP logo theme and dropped:
# not worth it for the second of logo it kept). The session (straight to its lock screen) is
# the first thing drawn. /etc/default/limine is bash; each
# KERNEL_CMDLINE[default]+= line appends to the kernel command line.
no_splash='KERNEL_CMDLINE[default]+=" plymouth.enable=0"'
if $limine && ! grep -qxF "$no_splash" /etc/default/limine; then
    echo "$no_splash" | sudo tee -a /etc/default/limine >/dev/null
    rebuild_boot=true
fi

# A quiet console: tty1 shows before the desktop, and at logout and
# shutdown, so no kernel or boot messages below errors, no systemd status unless something is
# slow or fails, and no blinking text cursor (a recovery login on Ctrl+Alt+F2 has none either;
# `setterm --cursor on` brings it back there).
quiet_console='KERNEL_CMDLINE[default]+=" loglevel=3 rd.udev.log_level=3 systemd.show_status=auto vt.global_cursor_default=0"'
if $limine && ! grep -qxF "$quiet_console" /etc/default/limine; then
    echo "$quiet_console" | sudo tee -a /etc/default/limine >/dev/null
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

# `splash` is Plymouth's, which is gone: the kernel only logs it as an unknown option. The line
# the 2026-11-04 try added goes whole; a `splash` in CachyOS's own line is cut out of it.
if $limine && grep -qxF 'KERNEL_CMDLINE[default]+=" splash"' /etc/default/limine; then
    sudo sed -i '/^KERNEL_CMDLINE\[default\]+=" splash"$/d' /etc/default/limine
    rebuild_boot=true
fi
# That try's Plymouth drop-in (it kept the logo on screen and crashed Hyprland's first start).
if [[ -e /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf ]]; then
    sudo rm /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf
    sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/plymouth-quit.service.d
    sudo systemctl daemon-reload
fi
if $limine && grep -Eq '^KERNEL_CMDLINE.* splash( |")' /etc/default/limine; then
    sudo sed -i -E '/^KERNEL_CMDLINE/ s/ splash( |")/\1/' /etc/default/limine
    rebuild_boot=true
fi

if $rebuild_boot && $limine; then
    # limine-mkinitcpio (CachyOS) rebuilds the initramfs and rewrites the Limine boot entries.
    sudo limine-mkinitcpio
elif $rebuild_boot; then
    sudo mkinitcpio -P
fi
if ! $limine; then
    printf '\033[1;33mnote:\033[0m not Limine: add "plymouth.enable=0 loglevel=3 rd.udev.log_level=3 systemd.show_status=auto vt.global_cursor_default=0" to your boot loader'"'"'s kernel line by hand.\n' >&2
fi
if $limine; then
    # Stop if the option didn't reach the boot entries. Only the kernels' own entries (two slashes
    # deep, "//linux-cachyos"): the snapshot entries further down ("////linux-cachyos",
    # limine-snapper-sync) keep the kernel line from when each was taken.
    # /etc/default/limine is bash written for limine-entry-tool, which declares KERNEL_CMDLINE as a
    # named (associative) array first; sourced bare, `[default]` is read as an unset variable under
    # set -u.
    esp=$(declare -A KERNEL_CMDLINE; . /etc/default/limine; echo "${ESP_PATH:-/boot}")
    sudo test -f "$esp/limine.conf" || fail "$esp/limine.conf is missing; check ESP_PATH in /etc/default/limine"
    cmdlines=$(sudo awk '/^ *\//{ match($0, /\/+/); depth = RLENGTH } /cmdline:/ && depth == 2' "$esp/limine.conf")
    [[ -n $cmdlines ]] || fail "no kernel entries in $esp/limine.conf; run sudo limine-mkinitcpio"
    ! grep -vqF 'plymouth.enable=0' <<<"$cmdlines" \
        || fail "a kernel entry in $esp/limine.conf has no plymouth.enable=0; check /etc/default/limine and run sudo limine-mkinitcpio"

    step "Boot menu: the HP logo stays, the menu only on a key"
    # Limine's own options, at the top of its config (limine-entry-tool, which rewrites the boot
    # entries, keeps them): firmware_logo puts the firmware's logo back when Limine hands over; quiet hides the menu unless a key is pressed during
    # the timeout (to pick Windows or a snapshot). $esp is read in the step above.
    limine_conf=$esp/limine.conf
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
fi

step "Logging in (greetd)"
# Your user for the automatic login at boot and after a logout (config.toml's default_session):
# the session locks at once, there's no separate login screen.
sed "s/@USER@/$USER/" system/etc/greetd/config.toml >"${TMPDIR:-/tmp}/ghost-greetd.toml"
sudo install -Dm644 "${TMPDIR:-/tmp}/ghost-greetd.toml" /etc/greetd/config.toml
rm -f "${TMPDIR:-/tmp}/ghost-greetd.toml"
# Its ordering after Plymouth (installed until 2026-11-04) is greetd's own unit's already, and
# there's no Plymouth: the copy goes.
if [[ -e /etc/systemd/system/greetd.service.d/after-plymouth.conf ]]; then
    sudo rm /etc/systemd/system/greetd.service.d/after-plymouth.conf
    sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/greetd.service.d
fi
sudo systemctl daemon-reload
# Enable only, don't start: starting it now would take over tty1 under the running session.
# It takes effect on the next boot.
sudo systemctl enable greetd.service
# The login screen that ran after a logout until 2026-11-04 (Quickshell as the greeter user):
# its copy of the shell, its Hyprland config and its home folder.
sudo rm -rf /etc/greetd/quickshell /etc/greetd/hypr /var/lib/qs-greeter

# The service that woke the RTX at shutdown (2026-11-04) didn't help, and pointed the wrong way
# (ROADMAP: "The RTX missing after a shutdown"): taken out where it was installed.
if [[ -e /etc/systemd/system/ghost-wake-dgpu.service ]]; then
    sudo systemctl disable --now ghost-wake-dgpu.service 2>/dev/null || true
    sudo rm /etc/systemd/system/ghost-wake-dgpu.service
    sudo systemctl daemon-reload
fi

step "Name lookup: one mDNS service (Avahi)"
mdns=system/etc/systemd/resolved.conf.d/50-no-mdns.conf
if ! cmp -s "$mdns" "/etc/systemd/resolved.conf.d/$(basename "$mdns")"; then
    sudo install -Dm644 "$mdns" "/etc/systemd/resolved.conf.d/$(basename "$mdns")"
    sudo systemctl try-restart systemd-resolved.service
fi

step "HP Omen 16-xf0: its bass speakers, and the RTX after a power-off"
# Only on that laptop (board 8BCA): the kernel leaves its bass speakers off (the patch file says
# why; it takes effect when the sound driver loads next, at the next boot), and powered off with
# the RTX on, the next boot often had none (ghost-hp-8bca-rtx-off.sh says why; from the next
# power-off on).
if [[ $(cat /sys/class/dmi/id/board_name 2>/dev/null) == 8BCA ]]; then
    for file in system/usr/lib/firmware/ghost-hp-8bca-speakers.fw system/etc/modprobe.d/ghost-hp-8bca-speakers.conf \
                system/etc/systemd/system/ghost-hp-8bca-rtx-off.service; do
        sudo install -Dm644 "$file" "/${file#system/}"
    done
    sudo install -Dm755 system/usr/local/lib/ghost-hp-8bca-rtx-off.sh /usr/local/lib/ghost-hp-8bca-rtx-off.sh
    sudo systemctl daemon-reload
    # Started now too: it does nothing at start, and its stop step needs it running at shutdown.
    sudo systemctl enable --now ghost-hp-8bca-rtx-off.service
else
    echo "Not an HP Omen 16-xf0 (board 8BCA): skipped"
fi

step "Services the Quickshell bar reads"
# Network, Bluetooth and power profile modules talk to these over D-Bus.
# UPower (battery) is started on demand by D-Bus, so it needs no enabling.
sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service
