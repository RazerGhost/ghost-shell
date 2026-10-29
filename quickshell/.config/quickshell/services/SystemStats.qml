// CPU, memory, GPUs, temperatures, disk and the busiest apps, for quick settings' System page. Read every 2 s by
// system-stats.sh (parsed by SystemStats.js), only while something wants them (`active`), so
// nothing polls while the page is closed.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
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
    property var apps: [] // the busiest, [{ name, icon, essential, cpu, memory, pids }]

    property var previousCpu: null
    property var previousTicks: ({}) // CPU ticks by process id at the last reading

    // Ends every process of an app (SIGTERM, so it can still save; like Windows' End task).
    function endTask(app: var): void {
        Quickshell.execDetached(["kill", ...app.pids.map(String)]);
        apps = apps.filter(a => a !== app);
    }

    // Windows' process ids -> their app, to group helper processes under it.
    function windowApps(): var {
        const result = {};
        for (const window of Hyprland.toplevels.values) {
            const pid = window.lastIpcObject?.pid;
            const appId = window.wayland?.appId ?? "";
            if (pid)
                result[pid] = { name: DesktopEntries.heuristicLookup(appId)?.name || appId, icon: Windows.iconFor(window) };
        }
        return result;
    }

    function amount(used: real, total: real): string {
        return Stats.amount(used, total);
    }

    function size(bytes: real): string {
        return Stats.size(bytes);
    }

    onActiveChanged: {
        if (active) {
            previousCpu = null;
            previousTicks = {};
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
                if (root.previousCpu && r.cpu)
                    root.apps = Stats.apps(r.procs, root.previousTicks, r.cpu.total - root.previousCpu.total, root.windowApps(), 6);
                root.previousTicks = Object.fromEntries(r.procs.map(p => [p.pid, p.ticks]));
                root.previousCpu = r.cpu;
                root.cpuTemp = r.cpuTemp;
                root.memory = r.memory;
                root.disk = r.disk;
                root.gpus = r.gpus;
            }
        }
    }
}
