pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "OomAlerts.js" as OomAlertsJs

// A notification when memory ran out and something was closed for it: an app or service the
// kernel's OOM killer or systemd-oomd ended, right away; or, at the next login, the whole
// session, which oomd closes as one (Hyprland, the shell and anything not started through
// Apps.run share its scope; nothing can show anything while it happens). Read from this boot's
// journal (no root), then followed.
Singleton {
    id: root

    readonly property string uid: (Quickshell.env("XDG_RUNTIME_DIR") ?? "").split("/").pop()
    // The newest kill already reported (journal time, microseconds), kept in a file so a shell
    // restart doesn't report it again. Without the file, only kills from now on count.
    property real seen: Number(seenFile.text()) || Date.now() * 1000

    // shell.qml reads this to start the service.
    readonly property bool watching: journal.running

    function report(kill: var): void {
        if (kill.time <= seen)
            return;
        seen = kill.time;
        seenFile.setText(String(kill.time));
        if (kill.session) {
            Notifications.send("System", "dialog-warning", "Memory ran out: your last session was closed",
                               "systemd-oomd ended it, with every app in it. Quick settings -> System shows what uses the most memory.",
                               false, []);
        } else {
            const name = DesktopEntries.heuristicLookup(kill.app)?.name || kill.app;
            Notifications.send("System", "dialog-warning", "Memory ran out: " + name + " was closed",
                               "The system closed it to keep running. Quick settings -> System shows what uses the most memory.",
                               false, []);
        }
    }

    FileView {
        id: seenFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/oom-seen"
        blockLoading: true // `seen` reads it right away
        printErrors: false // missing until the first kill
    }

    Process {
        id: journal
        command: ["journalctl", "-b", "-f", "-o", "json", "--grep", "Killed process|^Killed /"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const kill = OomAlertsJs.kill(line, root.uid);
                if (kill)
                    root.report(kill);
            }
        }
    }
}
