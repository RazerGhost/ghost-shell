#!/usr/bin/env bash
# The Elgato Wave:3 (USB 0fd9:0070) with openxlr instead of Wave Link: its daemon, and the "Voice"
# profile (Voice.json: openxlr's own noise removal, then LSP's EQ, a compressor, a de-esser and
# a limiter), recalled whenever the microphone connects. For the desktop it's plugged into: list
# this module in that machine's ~/.config/ghost/modules. See README.md here.
# Run by `ghost install`; alone: `ghost install wave3`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Elgato Wave:3 (openxlr)"
# The original Wave:3 only: the MK.2 and other models have other ids and other controls.
if ! lsusb -d 0fd9:0070 >/dev/null 2>&1; then
    found=$(lsusb | grep -i "0fd9:" || true)
    fail "no Wave:3 (0fd9:0070) is connected${found:+; Elgato devices found: $found}. Plug it in, or leave the wave3 module out of ~/.config/ghost/modules on this machine"
fi

# openxlr's daemon owns the microphone and the mixer, with the UI closed too.
systemctl --user enable --now openxlr-daemon

# The profile, copied (not linked: openxlr replaces its files when it saves them, which would
# turn a Stow link into a separate file). Only when it isn't there yet, so tuning saved from
# openxlr's UI stays; to put tuning back in the repo, see README.md.
profiles="$HOME/.config/openxlr/profiles/0fd9-0070"
mkdir -p "$profiles"
if [[ ! -f $profiles/Voice.json ]]; then
    install -m 600 modules/wave3/Voice.json "$profiles/Voice.json"
    echo "Added the Voice profile."
fi
# Recalled whenever the microphone connects (at login, after a replug), unless you chose another.
[[ -f $profiles/recall-on-connect ]] || printf 'Voice\n' > "$profiles/recall-on-connect"

echo "Replug the Wave:3 once after the first install, so the udev rule openxlr installed applies."
