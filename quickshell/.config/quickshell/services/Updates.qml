// Waiting system updates, for the island's status icons and quick settings: packages from the
// repositories (`checkupdates`, which checks a copy of pacman's database, so no root needed) and
// from the AUR (`paru -Qua`). Counted a minute after login, every hour, and after anything changes
// the installed packages (pacman's log changes). update() opens paru in a terminal.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Updates.js" as UpdatesJs

Singleton {
    id: root

    property list<string> repo: []
    property list<string> aur: []
    readonly property int count: repo.length + aur.length
    // "12 updates · 3 from the AUR"; "" when there are none.
    readonly property string summary: UpdatesJs.summary(repo.length, aur.length)

    function check(): void {
        if (!checker.running)
            checker.running = true;
    }

    // paru updates both; the terminal stays open at the end so you can read what happened.
    function update(): void {
        Apps.runInTerminal(["bash", "-c", "paru; echo; read -rp 'Done. Press Enter to close. '"]);
    }

    // qs ipc call updates check / summary
    IpcHandler {
        target: "updates"

        function check(): void {
            root.check();
        }

        function summary(): string {
            return root.summary || "No updates";
        }
    }

    Process {
        id: checker
        // Both list "name old -> new" per package and exit non-zero when there's nothing.
        command: ["sh", "-c", "checkupdates 2>/dev/null; echo '--- aur'; paru -Qua 2>/dev/null; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = UpdatesJs.parse(text);
                root.repo = found.repo;
                root.aur = found.aur;
            }
        }
    }

    // Not right at login: checkupdates and paru both go online.
    Timer {
        interval: 60 * 1000
        running: true
        onTriggered: root.check()
    }

    Timer {
        interval: 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.check()
    }

    // pacman writes its log for every install, removal and update, whoever runs it.
    FileView {
        path: "/var/log/pacman.log"
        watchChanges: true
        // Only its changes matter: don't read it (watching works without that, tested).
        preload: false
        printErrors: false
        onFileChanged: settle.restart()
    }

    // An update writes the log many times; count once it has been quiet for a few seconds.
    Timer {
        id: settle
        interval: 5000
        onTriggered: root.check()
    }
}
