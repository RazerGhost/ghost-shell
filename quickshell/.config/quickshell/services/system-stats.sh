#!/bin/sh
# One reading of the system for services/SystemStats.qml, one "key values..." line each (parsed
# by SystemStats.js). Sensors are found by name: hwmon numbers change between boots.
hwmon() { for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name")" = "$1" ] && echo "$h" && return; done; }

head -n 1 /proc/stat                                   # cpu user nice system idle iowait ...
awk '/^MemTotal:|^MemAvailable:/ { printf "%s %s\n", $1, $2 }' /proc/meminfo
k10=$(hwmon k10temp); [ -n "$k10" ] && echo "cputemp $(cat "$k10/temp1_input")"
df -B1 --output=size,used / | awk 'NR == 2 { print "disk", $1, $2 }'

for card in /sys/class/drm/card[0-9]; do
    dev="$card/device"
    case "$(cat "$dev/vendor" 2>/dev/null)" in
    0x1002) # AMD: load, VRAM and temperature from sysfs
        amd=$(hwmon amdgpu)
        echo "amdgpu $(cat "$dev/gpu_busy_percent") $(cat "$dev/mem_info_vram_used") $(cat "$dev/mem_info_vram_total") $(cat "$amd/temp1_input" 2>/dev/null || echo 0)"
        ;;
    0x10de) # NVIDIA: nvidia-smi would wake a sleeping card, so only ask an awake one
        if [ "$(cat "$dev/power/runtime_status")" = active ] && command -v nvidia-smi >/dev/null; then
            nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
                --format=csv,noheader,nounits | tr -d ',' | awk '{ print "nvidia", $1, $2 * 1048576, $3 * 1048576, $4 * 1000 }'
        else
            echo "nvidia asleep"
        fi
        ;;
    esac
done

# This user's processes: "proc pid ppid ticks rss_bytes name". The name sits in parentheses in
# the stat file and can hold spaces and parentheses itself, so it ends at the last ")".
page=$(getconf PAGESIZE)
ps -u "$(id -u)" -o pid= | awk '{ print "/proc/" $1 "/stat" }' | xargs awk -v page="$page" '{
    first = index($0, "("); last = 0
    while ((k = index(substr($0, last + 1), ")")) > 0) last += k
    split(substr($0, last + 2), f, " ")
    print "proc", $1, f[2], f[12] + f[13], f[22] * page, substr($0, first + 1, last - first - 1)
}' 2>/dev/null
