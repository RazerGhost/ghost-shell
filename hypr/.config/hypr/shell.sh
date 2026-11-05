#!/bin/sh
# Runs the Quickshell shell and starts it again if it crashes: the lock screen, idle, password
# prompts and notifications all live in it. A normal exit (0) or a deliberate stop (SIGTERM, e.g.
# `pkill -x qs`, exit 143) ends this too, so restarting it by hand doesn't leave two shells
# (run this script again after such a stop). A crash makes qs exit with 255.

# The shell draws on the AMD iGPU: give it Mesa's EGL only, so it doesn't also load NVIDIA's
# (about 57 MB less resident, measured 2026-10-29). Apps the shell starts would inherit it, so
# services/Apps.qml removes it for them: they keep both, and prime-run picks NVIDIA. Not where
# NVIDIA drives the display (ghost-hw, the same answer env.lua uses): the shell belongs on
# NVIDIA there (the desktop).
if ! "$HOME/.local/bin/ghost-hw" nvidia-display; then
    export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
fi

while :; do
    # The icon theme chosen in Settings (matugen's wallpaper.sh writes its dark or light version);
    # env.lua's Colloid-Dark otherwise. Read at every start, so a restart picks a new one up.
    icons=$(cat "$HOME/.local/state/quickshell/icon-theme" 2>/dev/null)
    case "$icons" in
        "" | *[!A-Za-z0-9_-]*) ;;
        *) export QS_ICON_THEME="$icons" ;;
    esac
    qs
    code=$?
    [ "$code" -eq 0 ] || [ "$code" -eq 143 ] && exit 0
    echo "shell.sh: qs exited with $code, restarting" >&2
    sleep 1
done
