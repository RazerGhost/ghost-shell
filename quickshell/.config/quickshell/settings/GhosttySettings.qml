import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "TerminalConfig.js" as TerminalConfig

// Applies Settings -> Terminal's Ghostty options (the cursor trail, notifications when a long
// command ends): writes ~/.config/ghostty/shell-settings, which Ghostty's config includes, and
// tells open Ghostty windows to reload (SIGUSR2, as matugen's colors do). Only when the text
// changes, so a shell start leaves Ghostty alone.
Scope {
    id: root

    readonly property string text: TerminalConfig.ghostty(Settings.values)

    onTextChanged: {
        if (Settings.loaded)
            writeLater.restart();
    }
    Connections {
        target: Settings
        function onLoadedChanged(): void {
            if (Settings.loaded)
                writeLater.restart();
        }
    }
    Component.onCompleted: {
        if (Settings.loaded)
            writeLater.restart();
    }

    Timer {
        id: writeLater
        interval: 400
        onTriggered: {
            if (file.loaded && file.text() === root.text)
                return;
            file.setText(root.text);
            Quickshell.execDetached(["sh", "-c", "pkill -SIGUSR2 -x ghostty || true"]);
        }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/ghostty/shell-settings"
        blockWrites: true
        printErrors: false // not there before the first write
    }
}
