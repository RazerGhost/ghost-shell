#!/usr/bin/env bash
# The calendar module: nothing to set up until a calendar is added (`ghost calendar add`), which
# writes vdirsyncer's and khal's configs; re-running this writes them again from the list.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Calendars"
# The shell watches khal's config to know a calendar was added; it can only watch for a file in
# a folder that exists.
mkdir -p "$HOME/.config/khal"
modules/calendar/calendar.sh configure
