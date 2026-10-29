import QtQuick
import Quickshell.Io

// A Process for "run this for the newest request": asked to run while it's still running, it
// runs once more when it's done (with the newest command) instead of dropping the request.
// Setting `running = true` on a running Process does nothing (NOTES.md), which lost the
// launcher's last calculation, a track's cover, a second wallpaper pick and the like. Call
// `start()` to run `command` as it's bound now, or `start(command)` to set it first. Readers of
// the output still check it's for the newest request: an older run finishes first. During
// Component.onCompleted `running` stays false until the event loop runs, so calls made there
// replace each other and only the last runs (verified with a throwaway `qs -p`).
Process {
    id: root

    property bool again: false
    property var nextCommand: undefined // for `again`; undefined keeps `command` as bound

    function start(newCommand: var): void {
        if (running) {
            again = true;
            nextCommand = newCommand;
            return;
        }
        if (newCommand !== undefined)
            command = newCommand;
        running = true;
    }

    onRunningChanged: {
        if (running || !again)
            return;
        const next = nextCommand;
        again = false;
        nextCommand = undefined;
        Qt.callLater(() => root.start(next));
    }
}
