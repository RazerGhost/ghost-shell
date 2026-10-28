#!/usr/bin/env bash
# Web apps: a site in its own window (no tabs or address bar), in the launcher and the dock with its
# own icon. Each is a desktop entry in ~/.local/share/applications that opens the site with
# ungoogled-chromium's --app (Zen has no such mode). `ghost webapp` runs this.
#
#   ghost webapp add <name> <url> [icon]   icon: an image file or URL; without one, the site's
#                                          own (apple-touch-icon.png), else its favicon
#   ghost webapp remove <name>
#   ghost webapp list
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

apps="$HOME/.local/share/applications"
icons="$HOME/.local/share/icons/webapps"

# "WhatsApp Web" -> "whatsapp-web": the file names.
slug() {
    tr '[:upper:]' '[:lower:]' <<<"$1" | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//'
}

# The window class Chromium gives an --app window on Wayland, which the dock matches to the entry
# (StartupWMClass): host, "_" and the path with / as _, no query or fragment.
# https://example.com/foo/bar?x -> chrome-example.com__foo_bar-Default (checked on the laptop).
wm_class() {
    local rest=${1#*://} host path
    rest=${rest%%[?#]*}
    host=${rest%%/*}
    path=${rest#"$host"}
    [[ $path == /* ]] || path=/$path
    echo "chrome-${host}_${path//\//_}-Default"
}

is_image() {
    [[ -s $1 ]] && file --brief --mime-type "$1" | grep -q '^image/'
}

# Into $2: $1 (a file or URL), or the site's own icon, or its favicon from DuckDuckGo's icon
# service. A web app without one still works (the launcher shows a generic icon).
fetch_icon() {
    local source=$1 target=$2 host
    if [[ -n $source && -f $source ]]; then
        cp "$source" "$target"
        is_image "$target" || fail "$source isn't an image"
        return
    fi
    if [[ -n $source ]]; then
        curl -fsSL --max-time 15 -o "$target" "$source" && is_image "$target" || fail "couldn't download an image from $source"
        return
    fi
    host=$(sed -E 's#^https?://([^/]+).*#\1#' <<<"$url")
    curl -fsSL --max-time 15 -o "$target" "https://$host/apple-touch-icon.png" 2>/dev/null && is_image "$target" && return
    curl -fsSL --max-time 15 -o "$target" "https://icons.duckduckgo.com/ip3/$host.ico" 2>/dev/null && is_image "$target" && return
    rm -f "$target"
    echo "No icon found for $host; add one with: ghost webapp add \"$name\" $url <image file or URL>" >&2
}

cmd_add() {
    (($# >= 2)) || fail "usage: ghost webapp add <name> <url> [icon]"
    name=$1 url=$2
    local id icon
    [[ $name != *$'\n'* && -n $(slug "$name") ]] || fail "\"$name\" isn't a usable name"
    # The URL goes into the entry's Exec line, so nothing that would need quoting there.
    [[ $url =~ ^https?://[^[:space:]\"\'\`\$\\]+$ ]] || fail "\"$url\" isn't an http(s) address"
    command -v chromium >/dev/null || fail "ungoogled-chromium isn't installed (the apps module installs it)"
    id=$(slug "$name")
    mkdir -p "$apps" "$icons"
    icon="$icons/$id.png"
    fetch_icon "${3:-}" "$icon"
    [[ -f $icon ]] || icon=applications-internet

    # % is special in Exec (field codes), so it's doubled.
    cat >"$apps/webapp-$id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$url
Exec=chromium --app=${url//%/%%}
Icon=$icon
Categories=Network;WebBrowser;
StartupWMClass=$(wm_class "$url")
EOF
    echo "Added $name: $apps/webapp-$id.desktop"
}

cmd_remove() {
    (($# == 1)) || fail "usage: ghost webapp remove <name>"
    local id
    id=$(slug "$1")
    [[ -f $apps/webapp-$id.desktop ]] || fail "no web app called \"$1\" (ghost webapp list)"
    rm -f "$apps/webapp-$id.desktop" "$icons/$id.png"
    echo "Removed $1"
}

cmd_list() {
    local entry
    for entry in "$apps"/webapp-*.desktop; do
        [[ -f $entry ]] || continue
        printf '%-20s %s\n' "$(sed -n 's/^Name=//p' "$entry")" "$(sed -n 's/^Comment=//p' "$entry")"
    done
}

case ${1:-} in
    add) shift; cmd_add "$@" ;;
    remove) shift; cmd_remove "$@" ;;
    list) cmd_list ;;
    *) fail "usage: ghost webapp add <name> <url> [icon] | remove <name> | list" ;;
esac
