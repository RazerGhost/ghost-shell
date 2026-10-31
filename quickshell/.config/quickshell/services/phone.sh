#!/bin/sh
# Your phone through KDE Connect, for quick settings' Phone page (services/Phone.qml).
#   phone.sh status        one line per paired phone that's connected now:
#                          <id> TAB <name> TAB <battery 0-100, or empty> TAB <charging: true/false/empty>
#   phone.sh send <id>     asks for files (zenity) and sends them to the phone
#   phone.sh mount <id>    makes the phone's files browsable and prints where they are
# The battery comes from the daemon's battery plugin over D-Bus (kdeconnect-cli doesn't print it).
set -u

case ${1:-} in
status)
    kdeconnect-cli -a --id-name-only 2>/dev/null | while read -r id name; do
        [ -n "$id" ] || continue
        path=/modules/kdeconnect/devices/$id/battery
        charge=$(busctl --user get-property org.kde.kdeconnect "$path" org.kde.kdeconnect.device.battery charge 2>/dev/null | cut -d' ' -f2)
        charging=$(busctl --user get-property org.kde.kdeconnect "$path" org.kde.kdeconnect.device.battery isCharging 2>/dev/null | cut -d' ' -f2)
        printf '%s\t%s\t%s\t%s\n' "$id" "$name" "$charge" "$charging"
    done
    ;;
send)
    id=${2:?device id}
    files=$(zenity --file-selection --multiple --separator='
' --title="Send to your phone") || exit 0
    count=0
    echo "$files" | {
        while IFS= read -r file; do
            [ -n "$file" ] && kdeconnect-cli -d "$id" --share "$file" >/dev/null 2>&1 && count=$((count + 1))
        done
        [ "$count" -eq 1 ] && what="1 file" || what="$count files"
        notify-send -a "Phone" -i smartphone "Sent to your phone" "$what"
    }
    ;;
mount)
    id=${2:?device id}
    kdeconnect-cli -d "$id" --mount >/dev/null 2>&1
    kdeconnect-cli -d "$id" --get-mount-point 2>/dev/null
    ;;
*)
    echo "usage: phone.sh status | send <id> | mount <id>" >&2
    exit 2
    ;;
esac
