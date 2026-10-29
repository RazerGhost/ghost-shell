#!/bin/sh
# Whether a camera is in use, for services/Privacy.qml (parsed by Privacy.js): "in-use" when
# one is, then "app <name>" for each process holding it. A USB camera is powered up ("active")
# only while an app has it open, so its power state shows it without reading every process;
# cameras that never sleep (power control "on") can't be told apart and are skipped.
used=""
for dev in /sys/class/video4linux/video*/device/..; do
    [ "$(cat "$dev/power/control" 2>/dev/null)" = auto ] || continue
    [ "$(cat "$dev/power/runtime_status" 2>/dev/null)" = active ] && used=1
done
[ -n "$used" ] || exit 0
echo in-use
for pid in $(fuser /dev/video* 2>/dev/null); do
    echo "app $(cat "/proc/$pid/comm" 2>/dev/null)"
done
