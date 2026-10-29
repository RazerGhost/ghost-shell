// Light or dark for everything (Settings -> Appearance): "dark", "light" or "auto" (dark from
// sunset to sunrise at the weather town; ColorScheme.js, tested). When the result changes it's
// written to ~/.local/state/quickshell/scheme and matugen's wallpaper.sh makes the colors again
// from the current wallpaper (and sets GTK's light or dark). Only on a change, so starting the
// shell doesn't regenerate the colors.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ColorScheme.js" as ColorSchemeJs
import "Schedule.js" as Schedule

Singleton {
    id: root

    readonly property string mode: ColorSchemeJs.mode(Settings.values.colorScheme, Schedule.minutesOf(clock.date),
                                                      Weather.current?.sunrise ?? null, Weather.current?.sunset ?? null)
    readonly property string file: Quickshell.env("HOME") + "/.local/state/quickshell/scheme"

    onModeChanged: {
        if (Settings.loaded)
            applyLater.restart();
    }

    Connections {
        target: Settings

        function onLoadedChanged(): void {
            if (Settings.loaded)
                applyLater.restart();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Clicking through the choices quickly makes the colors once.
    Timer {
        id: applyLater
        interval: 600
        onTriggered: {
            current.reload();
            if (current.text().trim() === root.mode || apply.running)
                return;
            apply.command = ["sh", "-c", `printf '%s\\n' "$1" > "$2" && sh "$3"`, "sh", root.mode, root.file,
                             Quickshell.env("HOME") + "/.config/matugen/wallpaper.sh"];
            apply.running = true;
        }
    }

    FileView {
        id: current
        path: root.file
        blockLoading: true // compared with right away
        printErrors: false // missing until the first switch
    }

    Process {
        id: apply
        onExited: code => {
            if (code !== 0)
                console.warn("ColorScheme: wallpaper.sh exited with code " + code);
        }
    }
}
