#!/usr/bin/env bash
# Btrfs snapshots (needs sudo): the system's (CachyOS sets them up: before and after every update,
# bootable from the boot menu) and hourly ones of your home folder, which had none. Your user may
# list and take them without sudo (the settings app's Snapshots page). ~/.cache and the Steam
# library are kept out of the home snapshots: they change a lot and would make them grow.
# Run by `ghost install`; alone: `ghost install snapshots`. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/../.."
. modules/lib.sh

if [[ $(findmnt -no FSTYPE /) != btrfs ]]; then
    echo "Skipped: / isn't Btrfs."
    exit 0
fi

step "Snapshots: the system"
# Created by the CachyOS installer; made here on other machines.
sudo snapper list-configs | grep -q '^root ' || sudo snapper -c root create-config /
sudo snapper -c root set-config "ALLOW_USERS=$USER" SYNC_ACL=yes
sudo systemctl enable --now limine-snapper-sync.service snapper-cleanup.timer

step "Snapshots: your home folder, hourly"
# Folders that are their own subvolume aren't part of a snapshot of /home. Turning a folder into
# one: copy it into a new subvolume (reflink copies share the data, so it's quick and takes no
# space), then swap them.
to_subvolume() {
    local dir=$1
    [[ -d $dir ]] || mkdir -p "$dir"
    if [[ $(stat -f -c %T "$dir") == btrfs ]] && sudo btrfs subvolume show "$dir" >/dev/null 2>&1; then
        return 0
    fi
    sudo btrfs subvolume create "$dir.new" >/dev/null
    sudo chown "$USER:$USER" "$dir.new"
    cp -a --reflink=always "$dir/." "$dir.new/"
    mv "$dir" "$dir.old"
    mv "$dir.new" "$dir"
    rm -rf "$dir.old"
    echo "$dir is now left out of the home snapshots (apps using it see the change after they"
    echo "restart: log out and back in once)."
}
to_subvolume "$HOME/.cache"
if pgrep -x steam >/dev/null; then
    echo "Skipped leaving the Steam library out: close Steam and run \`ghost install snapshots\` again."
else
    to_subvolume "$HOME/.local/share/Steam/steamapps"
fi

sudo snapper list-configs | grep -q '^home ' || sudo snapper -c home create-config /home
sudo snapper -c home set-config "ALLOW_USERS=$USER" SYNC_ACL=yes TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
    TIMELINE_LIMIT_HOURLY=10 TIMELINE_LIMIT_DAILY=7 TIMELINE_LIMIT_WEEKLY=4 \
    TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0
sudo systemctl enable --now snapper-timeline.timer
echo "Browse and restore them in Btrfs Assistant, or Settings -> Snapshots."
