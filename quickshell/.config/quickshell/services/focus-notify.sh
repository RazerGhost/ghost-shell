#!/bin/sh
# Focus mode's notification when a session's or a break's time is up (services/Focus.qml):
# waits for its button (notify-send prints the one pressed) and answers through the shell's
# IPC, so the buttons still work after a shell reload.
#   focus-notify.sh session <break minutes>   "Take a break" or "Focus again"
#   focus-notify.sh break <focus minutes>     "Focus again"
set -u
kind=$1 minutes=$2
if [ "$kind" = session ]; then
    set -- "--action=break=Take a $minutes-minute break" "--action=again=Focus again" \
        "Focus time is over" "Well done. Time for a short break?"
else
    set -- "--action=again=Focus again" "Break's over" "Ready for another $minutes minutes?"
fi
# Normal urgency: critical's error red read as a failure.
choice=$(notify-send --app-name=Focus --icon=appointment-soon --urgency=normal \
    --hint=string:sound-name:alarm-clock-elapsed "$@")
case $choice in
    break) qs ipc call focus takeBreak ;;
    again) qs ipc call focus again ;;
esac
