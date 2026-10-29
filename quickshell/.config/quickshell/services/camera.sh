#!/bin/sh
# Camera helpers for services/Privacy.qml (output parsed by Privacy.js):
#   camera.sh devices   the USB cameras' device folders, one per line: the shell reads their
#                       power/runtime_status itself every few seconds. A USB camera is powered up
#                       ("active") only while an app has it open; cameras that never sleep (power
#                       control "on") can't be told apart and are left out.
#   camera.sh apps      "app <name>" for each process holding a camera, run only while one is on.
case "${1-}" in
    devices)
        for dev in /sys/class/video4linux/video*/device/..; do
            [ "$(cat "$dev/power/control" 2>/dev/null)" = auto ] && readlink -f "$dev"
        done | sort -u
        ;;
    apps)
        for pid in $(fuser /dev/video* 2>/dev/null); do
            echo "app $(cat "/proc/$pid/comm" 2>/dev/null)"
        done
        ;;
    *)
        echo "usage: camera.sh devices | apps" >&2
        exit 2
        ;;
esac
