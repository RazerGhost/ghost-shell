#!/bin/sh
# The screenshot tool's follow-ups (screenshot/Screenshot.qml), each run detached:
#   capture.sh save <picture> <folder>
#                               copy it, and notify (naming the folder it's saved in): Open, or
#                               "Draw on it" in satty (Enter there saves the drawing over the
#                               picture and copies it)
#   capture.sh text <picture>   the text in it (tesseract), copied; the picture is removed
#   capture.sh qr <picture>     the QR code in it (zbarimg), copied; a link can be opened from the
#                               notification; the picture is removed
#   capture.sh color            the color picker (hyprpicker), #rrggbb copied

# An app in its own scope, like the ones the shell starts (Apps.run in services/Apps.qml): when
# memory runs out, oomd closes it rather than the session. Without the shell's Mesa-only EGL.
app() {
    systemd-run --user --scope --quiet --collect --slice=app.slice \
        env -u __EGL_VENDOR_LIBRARY_FILENAMES "$@"
}

case "${1-}" in
    save)
        file=$2 where=${3:-Pictures/Screenshots}
        wl-copy --type image/png < "$file"
        set -- -A default=Open
        command -v satty >/dev/null && set -- "$@" -A "draw=Draw on it"
        action=$(notify-send -a Screenshot -i "$file" "$@" "Screenshot saved" "Copied to the clipboard, and saved in $where")
        case "$action" in
            default) app xdg-open "$file" ;;
            draw) app satty --filename "$file" --output-filename "$file" --copy-command wl-copy \
                      --actions-on-enter save-to-clipboard,save-to-file,exit --save-after-copy ;;
        esac
        ;;
    text)
        text=$(tesseract "$2" - -l eng 2>/dev/null)
        rm -f "$2"
        if [ -n "$(printf %s "$text" | tr -d '[:space:]')" ]; then
            printf %s "$text" | wl-copy
            notify-send -a Screenshot -i edit-copy "Text copied" "$(printf %s "$text" | head -c 300)"
        else
            notify-send -a Screenshot "No text found" "Try a larger or sharper area"
        fi
        ;;
    qr)
        code=$(zbarimg -q --raw "$2" 2>/dev/null)
        rm -f "$2"
        if [ -n "$code" ]; then
            printf %s "$code" | wl-copy
            case $code in
                http://*|https://*)
                    action=$(notify-send -a Screenshot -A default=Open "QR code copied" "$code")
                    [ "$action" = default ] && app xdg-open "$code" ;;
                *) notify-send -a Screenshot "QR code copied" "$code" ;;
            esac
        else
            notify-send -a Screenshot "No QR code found" "Select the whole code"
        fi
        ;;
    color)
        # The overlay closes first, since hyprpicker draws its own.
        sleep 0.3
        color=$(hyprpicker -a -f hex) && [ -n "$color" ] && notify-send -a "Color picker" "Color copied" "$color"
        ;;
    *)
        echo "usage: capture.sh save|text|qr <picture> | color" >&2
        exit 2
        ;;
esac
