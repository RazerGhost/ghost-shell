#!/usr/bin/env bash
# Tests for modules/system/hardware/ (one fix per file, each for the hardware it names) and
# modules/system/packages.sh (packages by hardware): run from the repo root with
# `bash tests/hardware_fixes_test.sh`. Every fix is sourced on stand-in
# machines (a sysfs for ghost-hw) with sudo replaced by a log, so nothing is installed.
set -uo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
passed=0 failed=0
check() { # name, expected pattern, got
    if [[ $3 =~ $2 ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1: got '$3'"; fi
}

# A machine with a board name and its display GPU's vendor id (boot_vga).
machine() { # <name> <board> <display vendor>
    local sys=$scratch/$1/sys device=$scratch/$1/sys/bus/pci/devices/0000:01:00.0
    mkdir -p "$sys/class/dmi/id" "$device/drm"
    echo "$2" >"$sys/class/dmi/id/board_name"
    echo 0x030000 >"$device/class"
    echo "$3" >"$device/vendor"
    echo 1 >"$device/boot_vga"
}
# Every fix on a machine: what sudo would have run, and rebuild_boot.
fixes() { # <machine>
    GHOST_SYSFS=$scratch/$1/sys bash -c '
        . modules/lib.sh
        sudo() { echo "sudo $*"; }
        cmp() { return 1; }   # nothing installed yet
        rebuild_boot=false
        for fix in modules/system/hardware/*.sh; do . "$fix"; done
        echo "rebuild_boot=$rebuild_boot"'
}

# A second GPU beside the display one: <machine> <vendor id>
second_gpu() {
    local device=$scratch/$1/sys/bus/pci/devices/0000:65:00.0
    mkdir -p "$device/drm"
    echo 0x030000 >"$device/class"
    echo "$2" >"$device/vendor"
    echo 0 >"$device/boot_vga"
}
packages() { GHOST_SYSFS=$scratch/$1/sys modules/system/packages.sh | tr '\n' ' '; }

machine laptop 8BCA 0x1002
second_gpu laptop 0x10de
check "laptop packages: prime-run, no NVIDIA VA-API" '^nvidia-prime $' "$(packages laptop)"
out=$(fixes laptop)
check "laptop: amdgpu early" 'sudo install -Dm644 system/etc/mkinitcpio.conf.d/20-early-amdgpu.conf' "$out"
check "laptop: initramfs rebuilt" 'rebuild_boot=true' "$out"
check "laptop: bass speakers" 'ghost-hp-8bca-speakers.conf' "$out"
check "laptop: RTX off service" 'enable --now ghost-hp-8bca-rtx-off.service' "$out"

machine desktop "B650 EAGLE AX" 0x10de
second_gpu desktop 0x1002
check "desktop packages: NVIDIA VA-API, no prime-run" '^libva-nvidia-driver $' "$(packages desktop)"
machine amdonly X 0x1002
check "AMD only: no NVIDIA packages" '^$' "$(packages amdonly)"
check "--all: every one" '^nvidia-prime libva-nvidia-driver $' "$(modules/system/packages.sh --all | tr '\n' ' ')"
out=$(fixes desktop)
check "desktop: no amdgpu early" '^0$' "$(grep -c 'install.*20-early-amdgpu' <<<"$out")"
check "desktop: no HP fixes" '^0$' "$(grep -c '8bca' <<<"$out")"

for fix in modules/system/hardware/*.sh; do
    bash -n "$fix" && check "$fix: parses" . x || check "$fix: parses" ok fail
done

echo "$passed passed, $failed failed"
((failed == 0))
