import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "Fuzzy.js" as Fuzzy

// The launcher's "/ name": files in the home folder found by fd (hidden and git-ignored files are
// left out), once typing pauses. Parsed and sorted by Fuzzy.files (tested). The last results
// stay up until the new ones are in: clearing them on every key made the list empty and refill
// (and the launcher shrink and grow) as you typed.
Item {
    id: root

    // The file search typed now ("" when the launcher isn't searching files): results for older
    // text are dropped.
    property string current
    property var found: []
    property string asked: ""
    readonly property bool busy: fd.running || wait.running

    function ask(text: string): void {
        asked = text;
        if (text === "")
            found = [];
        else
            wait.restart();
    }

    Timer {
        id: wait
        interval: 200
        onTriggered: fd.start()
    }

    // Asked while fd still runs for older text, it searches once more when done.
    LatestProcess {
        id: fd
        command: ["fd", "--absolute-path", "--ignore-case", "--fixed-strings", "--max-results", "50",
                  "--", root.asked, Quickshell.env("HOME")]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.current === root.asked)
                    root.found = Fuzzy.files(text, Quickshell.env("HOME"));
            }
        }
    }
}
