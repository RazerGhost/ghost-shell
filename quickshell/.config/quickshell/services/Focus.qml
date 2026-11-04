// Focus mode (quick settings' round button): a 25-minute timer (the today menu's, shown in the
// island), pop-ups held back like Do Not Disturb (critical ones and apps set to "Always pop up"
// still show; one notification says how many came in when it ends), and the desktop widgets
// hidden. It lasts as long as the timer: it ends when time's up, when the timer is cancelled, or
// from the button (which also cancels the timer it started). A timer already running is used
// as it is. Kept across shell reloads, like the timer.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool on: saved.on
    readonly property int minutes: 25

    function start(): void {
        saved.startedTimer = !Countdown.active;
        if (saved.startedTimer)
            Countdown.run(minutes);
        saved.on = true;
    }

    function stop(): void {
        saved.on = false;
        if (saved.startedTimer && Countdown.active)
            Countdown.cancel();
        saved.startedTimer = false;
    }

    PersistentProperties {
        id: saved
        reloadableId: "focus"
        property bool on: false
        property bool startedTimer: false
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
                saved.startedTimer = false;
            }
        }
    }
}
