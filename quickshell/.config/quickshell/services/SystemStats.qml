// CPU, memory, GPUs, temperatures and disk, for quick settings' System page. Read every 2 s by
// system-stats.sh (parsed by SystemStats.js), only while something wants them (`active`), so
// nothing polls while the page is closed.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "SystemStats.js" as Stats

Singleton {
    id: root

    // Set while the System page is open.
    property bool active: false

    property real cpuLoad: -1 // 0-1; -1 until there are two readings to compare
    property var cpuTemp: null // °C
    property var memory: null // { used, total } in bytes
    property var disk: null
    property var gpus: [] // [{ name, asleep, load, memory, temp }]

    property var previousCpu: null

    function amount(used: real, total: real): string {
        return Stats.amount(used, total);
    }

    onActiveChanged: {
        if (active) {
            previousCpu = null;
            read.running = true;
        }
    }

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        onTriggered: read.running = true
    }

    Process {
        id: read
        command: ["sh", Quickshell.shellDir + "/services/system-stats.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const r = Stats.parse(text);
                const load = Stats.cpuLoad(root.previousCpu, r.cpu);
                if (load !== null)
                    root.cpuLoad = load;
                root.previousCpu = r.cpu;
                root.cpuTemp = r.cpuTemp;
                root.memory = r.memory;
                root.disk = r.disk;
                root.gpus = r.gpus;
            }
        }
    }
}
