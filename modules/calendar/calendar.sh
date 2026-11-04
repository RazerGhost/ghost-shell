#!/usr/bin/env bash
# Subscribed calendars for the today menu (read-only): Google Calendar's "Secret address in
# iCal format" (Settings -> the calendar -> Integrate calendar), or any other
# .ics address. vdirsyncer downloads each into ~/.local/share/calendars/<name>/
# (the shell runs `vdirsyncer sync` every 15 minutes) and khal reads them. `ghost calendar` runs
# this.
#
#   ghost calendar add [name]   takes the link from the clipboard (copy it first), or asks for
#                               it (not echoed, so it stays out of the terminal and the shell
#                               history); name: "google" if left out
#   ghost calendar remove <name>
#   ghost calendar list
#   ghost calendar sync         download them now
#
# The links are secrets (anyone with one can read the events), so they're kept in
# ~/.config/ghost/calendars and vdirsyncer's config, both readable only by you, never in the
# repo.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

list="$HOME/.config/ghost/calendars" # "name<tab>link" lines
data="$HOME/.local/share/calendars"

# "Work Stuff" -> "work-stuff": folder and section names.
slug() {
    tr '[:upper:]' '[:lower:]' <<<"$1" | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//'
}

names() {
    [[ -f $list ]] && cut -f1 "$list" || true
}

# vdirsyncer's and khal's configs from the list (both written whole: they're ours).
cmd_configure() {
    configure_vdirsyncer
    configure_khal
}

configure_vdirsyncer() {
    local name link
    [[ -s $list ]] || return 0
    command -v vdirsyncer >/dev/null && command -v khal >/dev/null \
        || fail "vdirsyncer and khal aren't installed (ghost install calendar)"
    mkdir -p "$HOME/.config/vdirsyncer" "$HOME/.config/khal" "$HOME/.local/state/vdirsyncer"
    (
        umask 077
        {
            echo "# Written by ghost calendar (modules/calendar/calendar.sh); don't edit: it's overwritten."
            echo "[general]"
            echo "status_path = \"~/.local/state/vdirsyncer/status/\""
            while IFS=$'\t' read -r name link; do
                cat <<EOT

[pair $name]
a = "${name}_remote"
b = "${name}_local"
collections = null
conflict_resolution = "a wins"

[storage ${name}_remote]
type = "http"
url = "$link"

[storage ${name}_local]
type = "filesystem"
path = "$data/$name/"
fileext = ".ics"
EOT
            done <"$list"
        } >"$HOME/.config/vdirsyncer/config"
    )
}

# The shell starts using the calendars when khal's config lists them (services/Agenda.qml), so
# a new calendar's goes in after its first sync: before, the shell's own sync raced discover's
# and failed ("Couldn't update the calendar" until the next one, 15 minutes later).
configure_khal() {
    local name
    [[ -s $list ]] || return 0
    {
        echo "# Written by ghost calendar (modules/calendar/calendar.sh); don't edit: it's overwritten."
        echo "[calendars]"
        while IFS=$'\t' read -r name _; do
            printf '[[%s]]\npath = %s/%s/\ntype = calendar\nreadonly = True\n' "$name" "$data" "$name"
        done <"$list"
        # Fixed formats: the shell reads khal's output (services/CalendarEvents.js).
        cat <<'EOT'
[locale]
timeformat = %H:%M
dateformat = %Y-%m-%d
longdateformat = %Y-%m-%d
datetimeformat = %Y-%m-%d %H:%M
longdatetimeformat = %Y-%m-%d %H:%M
firstweekday = 0
EOT
    } >"$HOME/.config/khal/config"
}

cmd_sync() {
    [[ -s $list ]] || fail "no calendars yet (ghost calendar add)"
    # discover sets the pairs up on the first run; `yes` answers its "create it?" questions. It
    # dies of SIGPIPE when discover is done, which pipefail would count as a failure.
    { yes || true; } | vdirsyncer discover >/dev/null
    vdirsyncer sync
}

cmd_add() {
    local name link
    name=$(slug "${1:-google}")
    [[ -n $name ]] || fail "\"$1\" isn't a usable name"
    names | grep -qx "$name" && fail "there's already a calendar called $name (ghost calendar remove $name)"
    # The clipboard first: pasting into a prompt that shows nothing looked like it hadn't worked.
    local copied answer
    copied=$(wl-paste --no-newline --type text 2>/dev/null || true)
    if [[ $copied =~ ^https://([^/[:space:]]+)/ ]]; then
        read -rp "Use the link on the clipboard (${BASH_REMATCH[1]}/…)? [Y/n] " answer
        [[ $answer =~ ^[Nn] ]] || link=$copied
    fi
    if [[ -z ${link:-} ]]; then
        read -rsp "Paste the calendar's link (it won't show), then Enter: " link
        echo
        echo "Got ${#link} characters."
    fi
    # Written into vdirsyncer's config inside quotes: nothing that would need escaping there.
    [[ $link =~ ^https://[^[:space:]\"\'\\]+$ ]] || fail "that isn't an https address"
    mkdir -p "$(dirname "$list")" "$data/$name"
    (umask 077; printf '%s\t%s\n' "$name" "$link" >>"$list")
    chmod 600 "$list"
    # Out of the clipboard and its history: anyone with the link can read the events.
    if [[ $copied == "$link" ]]; then
        wl-copy --clear
        cliphist delete-query "$link" 2>/dev/null || true
    fi
    configure_vdirsyncer
    cmd_sync
    configure_khal
    echo "Added $name: its events show in the today menu and the calendar widgets."
}

cmd_remove() {
    (($# == 1)) || fail "usage: ghost calendar remove <name>"
    local name
    name=$(slug "$1")
    names | grep -qx "$name" || fail "no calendar called \"$1\" (ghost calendar list)"
    awk -F'\t' -v n="$name" '$1 != n' "$list" >"$list.new" && mv "$list.new" "$list"
    chmod 600 "$list"
    # vdirsyncer's status is "<pair>" plus files starting "<pair>."; not a bare prefix, which
    # would also take "work-stuff" with "work".
    rm -rf "${data:?}/$name" "$HOME/.local/state/vdirsyncer/status/$name" "$HOME/.local/state/vdirsyncer/status/$name".*
    if [[ -s $list ]]; then
        cmd_configure
    else
        rm -f "$list" "$HOME/.config/vdirsyncer/config" "$HOME/.config/khal/config"
    fi
    echo "Removed $name"
}

case ${1:-} in
    add) shift; cmd_add "$@" ;;
    remove) shift; cmd_remove "$@" ;;
    list) names ;;
    sync) cmd_sync ;;
    configure) cmd_configure ;;
    *) fail "usage: ghost calendar add [name] | remove <name> | list | sync" ;;
esac
