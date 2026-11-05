#!/usr/bin/env bash
# Tests for bin/.local/bin/ghost-hw (what the machine's hardware is): run from the repo root with
# `bash tests/hw_test.sh`. Each machine is a stand-in sysfs, procfs and /dev in a scratch folder.
set -uo pipefail
cd "$(dirname "$0")/.."
hw=$PWD/bin/.local/bin/ghost-hw
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
passed=0 failed=0
check() { # name, expected, got
    if [[ $3 == "$2" ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL: $1: expected '$2', got '$3'"; fi
}

# A machine: machine <name> <chassis type> then gpu / battery / lid lines.
machine() {
    root=$scratch/$1
    mkdir -p "$root/sys/class/dmi/id" "$root/sys/bus/pci/devices" "$root/sys/class/power_supply" "$root/proc" "$root/dev/dri"
    echo "$2" >"$root/sys/class/dmi/id/chassis_type"
    echo "Maker" >"$root/sys/class/dmi/id/sys_vendor"
    echo "Model $1" >"$root/sys/class/dmi/id/product_name"
    echo "BOARD-$1" >"$root/sys/class/dmi/id/board_name"
}
# gpu <machine> <pci address> <vendor id> <boot_vga or -> [nodriver]
gpu() {
    local device=$scratch/$1/sys/bus/pci/devices/$2
    mkdir -p "$device"
    echo 0x030000 >"$device/class"
    echo "$3" >"$device/vendor"
    [[ $4 != - ]] && echo "$4" >"$device/boot_vga"
    if [[ ${5:-} != nodriver ]]; then
        mkdir -p "$device/drm"
        touch "$scratch/$1/dev/dri/gpu-pci-${2//[:.]/_}"
    fi
}
battery() { # <machine> <name> <scope>
    mkdir -p "$scratch/$1/sys/class/power_supply/$2"
    echo Battery >"$scratch/$1/sys/class/power_supply/$2/type"
    echo "$3" >"$scratch/$1/sys/class/power_supply/$2/scope"
}
lid() { mkdir -p "$scratch/$1/proc/acpi/button/lid/LID0"; }
ask() { # <machine> <question...>: its output, then yes or no
    local out
    out=$(GHOST_SYSFS=$scratch/$1/sys GHOST_PROCFS=$scratch/$1/proc GHOST_DEVFS=$scratch/$1/dev "$hw" "${@:2}")
    local code=$?
    [[ -n $out ]] && echo "$out" || { ((code == 0)) && echo yes || echo no; }
}

# The hybrid laptop: the AMD chip drives the built-in screen, the RTX is for offloading.
machine laptop 10
gpu laptop 0000:01:00.0 0x10de 0
gpu laptop 0000:65:00.0 0x1002 1
battery laptop BAT0 System
lid laptop
check "laptop: laptop" yes "$(ask laptop laptop)"
check "laptop: battery" yes "$(ask laptop battery)"
check "laptop: lid" yes "$(ask laptop lid)"
check "laptop: display GPU" amd "$(ask laptop display-gpu)"
check "laptop: NVIDIA doesn't drive the display" no "$(ask laptop nvidia-display)"
check "laptop: NVIDIA for offloading" yes "$(ask laptop nvidia-offload)"
check "laptop: the AMD chip first" "$scratch/laptop/dev/dri/gpu-pci-0000_65_00_0:$scratch/laptop/dev/dri/gpu-pci-0000_01_00_0" "$(ask laptop drm-devices)"
check "laptop: its board" yes "$(ask laptop board BOARD-laptop)"
check "laptop: another board" no "$(ask laptop board BOARD)"
check "laptop: model match, any case" yes "$(ask laptop match "model LAPTOP")"
check "laptop: no match" no "$(ask laptop match desktop)"

# The desktop: the RTX drives the screens, the Ryzen's small iGPU is there too; a mouse's battery.
machine desktop 3
gpu desktop 0000:01:00.0 0x10de 1
gpu desktop 0000:0f:00.0 0x1002 0
battery desktop hidpp_battery_0 Device
check "desktop: not a laptop" no "$(ask desktop laptop)"
check "desktop: a mouse's battery doesn't count" no "$(ask desktop battery)"
check "desktop: no lid" no "$(ask desktop lid)"
check "desktop: display GPU" nvidia "$(ask desktop display-gpu)"
check "desktop: NVIDIA drives the display" yes "$(ask desktop nvidia-display)"
check "desktop: nothing to offload" no "$(ask desktop nvidia-offload)"
check "desktop: the RTX first" "$scratch/desktop/dev/dri/gpu-pci-0000_01_00_0:$scratch/desktop/dev/dri/gpu-pci-0000_0f_00_0" "$(ask desktop drm-devices)"

# No card marked boot_vga: NVIDIA is taken for the display GPU (Omarchy's rule).
machine noflag 3
gpu noflag 0000:03:00.0 0x1002 -
gpu noflag 0000:04:00.0 0x10de -
check "no boot_vga: NVIDIA" nvidia "$(ask noflag display-gpu)"

# Intel only, and an RTX without its driver: left out of the list, named as missing one.
machine intel 9
gpu intel 0000:00:02.0 0x8086 1
gpu intel 0000:01:00.0 0x10de 0 nodriver
check "intel: display GPU" intel "$(ask intel display-gpu)"
check "intel: an NVIDIA card without a driver isn't one" no "$(ask intel nvidia)"
check "intel: only the Intel card" "$scratch/intel/dev/dri/gpu-pci-0000_00_02_0" "$(ask intel drm-devices)"
check "intel: the card without a driver" "no_driver=nvidia 0000:01:00.0" "$(ask intel facts | grep '^no_driver=')"

# No GPU at all (a VM without one): nothing to list, display-gpu says no.
machine none 1
check "none: no display GPU" no "$(ask none display-gpu)"
check "none: no devices" no "$(ask none drm-devices)"

echo "$passed passed, $failed failed"
((failed == 0))
