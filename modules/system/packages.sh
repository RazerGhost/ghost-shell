#!/usr/bin/env bash
# The packages this machine's hardware needs, decided by ghost-hw at install time rather than
# listed for every machine: one per line, added to the module's packages.txt by `ghost install`
# and checked by `ghost doctor`. With --all, every package it may add (tests/deps_test.sh).
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh
all=false
[[ ${1:-} == --all ]] && all=true

# prime-run, to run an app on the RTX: only where NVIDIA sits beside the GPU that drives the
# display (the hybrid laptop).
if $all || hw nvidia-offload; then
    echo nvidia-prime
fi
# NVIDIA's VA-API driver, for video decoding where NVIDIA drives the display: env.lua sets
# LIBVA_DRIVER_NAME only when it's there.
if $all || hw nvidia-display; then
    echo libva-nvidia-driver
fi
