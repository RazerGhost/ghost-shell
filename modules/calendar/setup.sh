#!/usr/bin/env bash
# The calendar module: nothing to set up until a calendar is added (`ghost calendar add`), which
# writes vdirsyncer's and khal's configs; re-running this writes them again from the list.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

step "Calendars"
modules/calendar/calendar.sh configure
