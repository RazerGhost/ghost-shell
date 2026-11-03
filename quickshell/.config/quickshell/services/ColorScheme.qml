// How the colors are made (Settings -> Appearance): light or dark ("dark", "light" or "auto":
// dark from sunset to sunrise at the weather town), matugen's color style and contrast, and an
// optional fixed accent (ColorScheme.js, tested). When that changes it's written to
// ~/.local/state/quickshell/scheme and matugen's wallpaper.sh makes the colors again from the
// current wallpaper (and sets GTK's light or dark). Only on a change, so starting the shell
// doesn't regenerate the colors.
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
    // Everything wallpaper.sh makes the colors from: the mode, matugen's color style and contrast,
    // and a fixed accent (ColorScheme.js, tested). A change to any of them makes the colors again.
    readonly property string wanted: ColorSchemeJs.file(mode, Settings.values.colorStyle,
                                                        Settings.values.colorContrast, Settings.values.accentColor,
                                                        Settings.values.iconTheme)
    // "At sunset" with a weather town waits for the town's sunset (or the weather failing), so a
    // start between the real sunset and the 19:00 fallback doesn't recolor everything twice.
    readonly property bool known: Settings.values.colorScheme !== "auto" || Settings.values.weatherLocation === ""
                                  || Weather.current !== null || Weather.error !== ""

    onWantedChanged: {
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

    Connections {
        target: Wallpaper

        function onRunningChanged(): void {
            if (!Wallpaper.running && Settings.loaded)
                applyLater.restart();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // What the colors were last made for: the file's at start (read once), then remembered
    // here. Not re-read after a run: the read right after came back stale, so every switch ran
    // twice (logged 2026-10-29).
    property string applied: ""
    property bool appliedRead: false
    // The mode the colors were last made in. The wallpaper follows this one, not `mode`: its
    // switch to a picture's dark or light version then runs after these colors are made, not
    // alongside (both run wallpaper.sh), and only once "At sunset" knows the sunset.
    property string appliedMode: ""
    // The colors are being made again (light or dark, color style, contrast, accent changed).
    readonly property bool busy: apply.running || applyLater.running

    // Clicking through the choices quickly makes the colors once.
    Timer {
        id: applyLater
        interval: 300
        onTriggered: {
            // A change during a run is picked up when it ends (apply's onExited). A wallpaper's
            // run read the old scheme file when it started: running alongside, whichever ends
            // last would win, so wait for it too (picked up by the Connections below). Not for a
            // wallpaper waiting on us (`Wallpaper.busy`): that one runs after this.
            if (!root.known || apply.running || Wallpaper.running)
                return;
            if (!root.appliedRead) {
                root.applied = current.text();
                root.appliedRead = true;
            }
            if (root.applied === root.wanted) {
                root.appliedMode = ColorSchemeJs.modeOf(root.applied);
                return;
            }
            root.applied = root.wanted;
            apply.command = ["sh", "-c", `printf '%s' "$1" > "$2" && sh "$3"`, "sh", root.wanted, root.file,
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
            else
                root.appliedMode = ColorSchemeJs.modeOf(root.applied);
            applyLater.restart(); // the choice may have changed while it ran
        }
    }
}
