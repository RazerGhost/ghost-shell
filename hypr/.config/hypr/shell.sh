#!/bin/sh
# Runs the Quickshell shell and starts it again if it crashes: the lock screen, idle, password
# prompts and notifications all live in it. A normal exit (0) or a deliberate stop (SIGTERM, e.g.
# `pkill -x qs`, exit 143) ends this too, so restarting it by hand doesn't leave two shells
# (run this script again after such a stop). A crash makes qs exit with 255.
while :; do
    qs
    code=$?
    [ "$code" -eq 0 ] || [ "$code" -eq 143 ] && exit 0
    echo "shell.sh: qs exited with $code, restarting" >&2
    sleep 1
done
