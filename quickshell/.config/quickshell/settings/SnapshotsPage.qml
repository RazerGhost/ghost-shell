import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "SnapshotList.js" as SnapshotList

// Snapshots (the snapshots module, snapper on Btrfs): the system's, taken before and after every
// update and bootable from the boot menu, and the home folder's, hourly. Lists the latest (your
// user may read them: ALLOW_USERS), opens a home snapshot's files in the file manager to copy
// something back, takes one by hand, and opens Btrfs Assistant for the rest.
Column {
    id: page

    property var systemRows: []
    property var homeRows: []
    property bool available: true

    spacing: Theme.spacing.l

    function refresh(): void {
        list.running = true;
    }

    onVisibleChanged: {
        if (visible)
            refresh();
    }
    // Settings builds the page when it's chosen, already visible.
    Component.onCompleted: refresh()

    // Both lists in one go, as JSON objects one after the other on separate lines.
    Process {
        id: list
        command: ["sh", "-c", "snapper -c root --jsonout list | tr -d '\\n'; echo; snapper -c home --jsonout list | tr -d '\\n'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [system, home] = text.trim().split("\n").map(line => {
                    try {
                        return JSON.parse(line);
                    } catch (e) {
                        return null;
                    }
                });
                page.available = system !== null;
                page.systemRows = SnapshotList.rows(system, "root", 5);
                page.homeRows = SnapshotList.rows(home, "home", 5);
            }
        }
    }

    Process {
        id: take
        command: ["snapper", "-c", "home", "create", "--description", "By hand", "--cleanup-algorithm", "number"]
        onExited: page.refresh()
    }

    // "28 okt 22:37" from snapper's "2026-10-28 22:37:32".
    function when(date: string): string {
        const d = new Date(date.replace(" ", "T"));
        return isNaN(d) ? date : Qt.formatDateTime(d, "d MMM HH:mm");
    }

    Text {
        visible: !page.available
        width: parent.width
        leftPadding: Theme.spacing.l
        text: "Snapshots aren't set up on this machine: run ghost install snapshots."
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        wrapMode: Text.Wrap
    }

    SettingGroup {
        visible: page.available
        title: "System"

        SettingRow {
            title: "Before and after every update"
            subtitle: "If an update breaks something, pick an older snapshot in the boot menu"
        }

        Repeater {
            model: page.systemRows

            SettingRow {
                required property var modelData
                title: modelData.label
                subtitle: page.when(modelData.date)
            }
        }
    }

    SettingGroup {
        visible: page.available
        title: "Home folder"

        SettingRow {
            title: "Every hour"
            subtitle: "Kept: the last 10 hours, 7 days and 4 weeks. Not your cache or Steam games"

            TextButton {
                text: "Take one now"
                enabled: !take.running
                onClicked: take.running = true
            }
        }

        Repeater {
            model: page.homeRows

            SettingRow {
                required property var modelData
                title: modelData.label
                subtitle: page.when(modelData.date)

                // The files as they were, to copy something back.
                TextButton {
                    text: "Open"
                    onClicked: Quickshell.execDetached(["xdg-open", "/home/.snapshots/" + modelData.number + "/snapshot/" + Quickshell.env("USER")])
                }
            }
        }

        SettingRow {
            visible: page.homeRows.length === 0
            title: "None yet"
            subtitle: "The first comes at the next full hour"
        }
    }

    SettingGroup {
        visible: page.available
        title: "Restoring"

        SettingRow {
            title: "Btrfs Assistant"
            subtitle: "Browse every snapshot, compare them and restore a whole one"

            TextButton {
                text: "Open"
                onClicked: Quickshell.execDetached(["btrfs-assistant"])
            }
        }
    }
}
