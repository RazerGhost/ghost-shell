// Focus mode (quick settings' round button): a 25-minute timer (the today menu's, shown in the
// island), pop-ups held back like Do Not Disturb (critical ones and apps set to "Always pop up"
// still show; one notification says how many came in when it ends), and the desktop widgets
// hidden. It lasts as long as the timer: it ends when time's up, when the timer is cancelled, or
// from the button (which also cancels the timer it started). A timer already running is used
// as it is. Hyprland's bell for apps is quiet too (settings/HyprlandSettings.qml). The lock
// screen still shows the widgets: it's the desktop, locked, where nobody is working. Kept
// across shell reloads, like the timer.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool on: saved.on
    readonly property int minutes: 25

    function start(): void {
        if (!Countdown.active) {
            Countdown.run(minutes);
            saved.timer = Countdown.runs;
        } else {
            saved.timer = -1;
        }
        saved.on = true;
    }

    function stop(): void {
        saved.on = false;
        // Only the timer it started: not one already running, or one started over it since.
        if (Countdown.active && Countdown.runs === saved.timer)
            Countdown.cancel();
        saved.timer = -1;
    }

    PersistentProperties {
        id: saved
        reloadableId: "focus"
        property bool on: false
        property int timer: -1 // Countdown.runs of the timer it started, else -1
    }

    IpcHandler {
        target: "focus"

        function toggle(): void {
            root.on ? root.stop() : root.start();
        }
    }

    // The timer ended (time's up, or cancelled in the today menu or a widget): so does focus.
    Connections {
        target: Countdown
        function onActiveChanged(): void {
            if (!Countdown.active && saved.on) {
                saved.on = false;
                saved.timer = -1;
            }
        }
    }
}
