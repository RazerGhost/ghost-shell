pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "DiskAlerts.js" as DiskAlertsJs

// A notification when the disk gets full: under 10 % free, and a critical one (stays until
// dismissed) under 5 %, each once until there's room again (above 15 %). Hourly home snapshots
// and the ones around every update fill Btrfs without anyone noticing, so the warning points at
// them. Checked a minute after login and every 10 minutes (`df`, no root).
Singleton {
    id: root

    property string given: ""

    function check(): void {
        df.running = true;
    }

    Process {
        id: df
        command: ["df", "-B1", "--output=avail,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const disk = DiskAlertsJs.parse(text);
                if (!disk)
                    return;
                const result = DiskAlertsJs.check(disk.avail, disk.size, root.given);
                root.given = result.given;
                if (result.warning === "")
                    return;
                const critical = result.warning === "critical";
                notify.command = ["notify-send", "--app-name=Disk", "--icon=drive-harddisk",
                    "--urgency=" + (critical ? "critical" : "normal"),
                    (critical ? "Disk almost full: " : "Disk space low: ") + DiskAlertsJs.size(disk.avail) + " free",
                    "Old snapshots take space too: Settings -> Snapshots, or Btrfs Assistant to remove them."];
                notify.running = true;
            }
        }
    }

    Process {
        id: notify
    }

    Timer {
        interval: 60 * 1000
        running: true
        onTriggered: {
            root.check();
            interval = 10 * 60 * 1000;
            repeat = true;
            restart();
        }
    }
}
