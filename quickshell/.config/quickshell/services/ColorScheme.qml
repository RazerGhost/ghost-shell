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
    // "At sunset" with a weather town waits for the town's sunset (or the weather failing), so a
    // start between the real sunset and the 19:00 fallback doesn't recolor everything twice.
    readonly property bool known: Settings.values.colorScheme !== "auto" || Settings.values.weatherLocation === ""
                                  || Weather.current !== null || Weather.error !== ""

    onModeChanged: {
        if (Settings.loaded)
            applyLater.restart();
    }
    onKnownChanged: {
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

    // The mode the colors were last made for: the file's at start (read once), then remembered
    // here. Not re-read after a run: the read right after came back stale, so every switch ran
    // twice (logged 2026-10-29).
    property string applied: ""
    property bool appliedRead: false

    // Clicking through the choices quickly makes the colors once.
    Timer {
        id: applyLater
        interval: 300
        onTriggered: {
            // A change during a run is picked up when it ends (apply's onExited).
            if (!root.known || apply.running)
                return;
            if (!root.appliedRead) {
                root.applied = current.text().trim();
                root.appliedRead = true;
            }
            if (root.applied === root.mode)
                return;
            root.applied = root.mode;
            apply.command = ["sh", "-c", `printf '%s\\n' "$1" > "$2" && sh "$3"`, "sh", root.mode, root.file,
                             Quickshell.env("HOME") + "/.config/matugen/wallpaper.sh"];
            apply.running = true;
        }
    }

    FileView {
        id: current
        path: root.file
        blockLoading: true // read once, right away
        printErrors: false // missing until the first switch
    }

    Process {
        id: apply
        onExited: code => {
            // A failed run isn't retried here (it would loop); the next change runs it again.
            if (code !== 0)
                console.warn("ColorScheme: wallpaper.sh exited with code " + code);
            applyLater.restart(); // the choice may have changed while it ran
        }
    }
}
