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
# repo, and vdirsyncer's messages are shown with them cut out (its errors print the address).
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

tools() {
    command -v vdirsyncer >/dev/null && command -v khal >/dev/null \
        || fail "vdirsyncer and khal aren't installed (ghost install calendar)"
}

# Runs vdirsyncer, its output shown with every address replaced by <link>; its exit code.
vdirsyncer_quiet() {
    local out code=0
    out=$({ yes || true; } | vdirsyncer "$@" 2>&1) || code=$?
    [[ -z $out ]] || sed -E "s#(https?|webcal)://[^[:space:]'\"]+#<link>#g" <<<"$out"
    return "$code"
}

# vdirsyncer's and khal's configs from the list (both written whole: they're ours).
cmd_configure() {
    configure_vdirsyncer
    configure_khal
}

configure_vdirsyncer() {
    local name link
    [[ -s $list ]] || return 0
    tools
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
    chmod 600 "$HOME/.config/vdirsyncer/config" # umask only applies to a new file
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

# All calendars, or the ones named. discover sets a pair up on its first run (vdirsyncer
# won't sync one it hasn't); `yes` answers its "create it?" questions.
cmd_sync() {
    [[ -s $list ]] || fail "no calendars yet (ghost calendar add)"
    vdirsyncer_quiet --verbosity WARNING discover "$@" && vdirsyncer_quiet --verbosity WARNING sync "$@"
}

# Takes a calendar out of the list and its downloaded events and sync state with it, then
# writes the configs again (or removes them with the last one, links and all).
forget() {
    awk -F'\t' -v n="$1" '$1 != n' "$list" >"$list.new" && mv "$list.new" "$list"
    chmod 600 "$list"
    # vdirsyncer's status is "<pair>" plus files starting "<pair>."; not a bare prefix, which
    # would also take "work-stuff" with "work".
    rm -rf "${data:?}/$1" "$HOME/.local/state/vdirsyncer/status/$1" "$HOME/.local/state/vdirsyncer/status/$1".*
    if [[ -s $list ]]; then
        cmd_configure
    else
        rm -f "$list" "$HOME/.config/vdirsyncer/config" "$HOME/.config/khal/config"
    fi
}

cmd_add() {
    local name link
    name=$(slug "${1:-google}")
    [[ -n $name ]] || fail "\"$1\" isn't a usable name"
    names | grep -qx "$name" && fail "there's already a calendar called $name (ghost calendar remove $name)"
    tools
    # The clipboard first: pasting into a prompt that shows nothing looked like it hadn't worked.
    local copied answer
    copied=$(wl-paste --no-newline --type text 2>/dev/null || true)
    if [[ $copied =~ ^(https|webcal)://([^/[:space:]]+)/ ]]; then
        read -rp "Use the link on the clipboard (${BASH_REMATCH[2]}/…)? [Y/n] " answer
        [[ $answer =~ ^[Nn] ]] || link=$copied
    fi
    if [[ -z ${link:-} ]]; then
        read -rsp "Paste the calendar's link (it won't show), then Enter: " link
        echo
        echo "Got ${#link} characters."
    fi
    # Apple's and Outlook's links are webcal://, which is https underneath.
    [[ $link == webcal://* ]] && link="https://${link#webcal://}"
    # Written into vdirsyncer's config inside quotes: nothing that would need escaping there.
    [[ $link =~ ^https://[^[:space:]\"\'\\]+$ ]] || fail "that isn't an https address"
    # Out of the clipboard and its history: anyone with the link can read the events. Matched by
    # the start of cliphist's preview, passed through the environment (an argument would show
    # in the process list).
    if [[ -n $copied && ( $copied == "$link" || $copied == "webcal://${link#https://}" ) ]]; then
        wl-copy --clear
        cliphist list | start="${copied:0:90}" awk -F'\t' 'index($2, ENVIRON["start"]) == 1' | cliphist delete \
            || echo "warning: couldn't take the link out of the clipboard history (Super+V: remove it there)" >&2
    fi
    mkdir -p "$(dirname "$list")" "$data/$name"
    (umask 077; printf '%s\t%s\n' "$name" "$link" >>"$list")
    chmod 600 "$list"
    configure_vdirsyncer
    # Only this one: another calendar failing mustn't stop it. If it can't be downloaded, it's
    # taken out again, so nothing is left half added.
    if ! cmd_sync "$name"; then
        forget "$name"
        fail "couldn't download that calendar (a wrong or expired link, or offline); nothing was added"
    fi
    configure_khal
    echo "Added $name: its events show in the today menu and the calendar widgets."
}

cmd_remove() {
    (($# == 1)) || fail "usage: ghost calendar remove <name>"
    local name
    name=$(slug "$1")
    names | grep -qx "$name" || fail "no calendar called \"$1\" (ghost calendar list)"
    forget "$name"
    echo "Removed $name"
}

case ${1:-} in
    add) shift; cmd_add "$@" ;;
    remove) shift; cmd_remove "$@" ;;
    list) names ;;
    sync) cmd_sync || fail "couldn't update the calendars (offline, or a link no longer works)"
          echo "Calendars updated" ;;
    configure) cmd_configure ;;
    *) fail "usage: ghost calendar add [name] | remove <name> | list | sync" ;;
esac
