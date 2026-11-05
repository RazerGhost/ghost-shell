// Nearby sharing (quick settings' round button): LocalSend (the phone module) running hidden in
// the background, so phones, tablets and computers nearby with LocalSend can send files here,
// like AirDrop's "receive". On starts it hidden (`localsend --hidden`, from its launcher), off
// stops it; whether it runs is read with pgrep while quick settings shows (`watching`).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool installed: DesktopEntries.applications.values.some(e => e.id === "localsend")
    property bool running: false
    property bool watching: false

    function toggle(): void {
        if (running)
            Quickshell.execDetached(["pkill", "-x", "localsend"]);
        else
            Apps.run(["localsend", "--hidden"], "localsend", "");
        running = !running; // shown at once; the next check corrects it
        checkSoon.restart();
    }

    Process {
        id: check
        command: ["pgrep", "-x", "localsend"]
        onExited: code => root.running = code === 0
    }

    Timer {
        running: root.watching
        triggeredOnStart: true
        repeat: true
        interval: 3000
        onTriggered: check.running = true
    }

    Timer {
        id: checkSoon
        interval: 1500
        onTriggered: check.running = true
    }
}
