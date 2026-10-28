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
