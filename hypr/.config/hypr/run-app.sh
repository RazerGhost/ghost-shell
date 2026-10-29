#!/bin/sh
# Starts an app in its own systemd scope in the user's app.slice, named like the XDG spec's
# app-<launcher>-<app id>-<random>.scope: run-app.sh <app id> <command> [arguments...]
# Without one, everything Hyprland or the shell starts shares Hyprland's session scope, and when
# memory runs out systemd-oomd would close that whole session instead of the app (NOTES.md).
# The shell's own Mesa-only EGL (shell.sh) isn't for the apps: prime-run needs NVIDIA's.
# Used by the shell (services/Apps.qml, Recorder.qml, screenshot/capture.sh) and rules.lua.
id=$(printf %s "$1" | tr -c 'A-Za-z0-9:_.' _)
shift
exec systemd-run --user --scope --quiet --collect --slice=app.slice \
    --unit="app-ghost-$id-$(od -An -N4 -tx4 /dev/urandom | tr -d ' \n')" \
    env -u __EGL_VENDOR_LIBRARY_FILENAMES "$@"
