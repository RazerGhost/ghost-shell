// The today menu's timer: counts down from a few minutes, can pause, and at zero sends a
// critical notification with the alarm sound (it stays until dismissed and also shows during Do
// Not Disturb). The island shows the time left while it runs. Kept across shell reloads.
pragma Singleton

import QtQuick
import Quickshell
import "Planner.js" as PlannerJs

Singleton {
    id: root

    readonly property bool active: saved.endsAt > 0 || saved.pausedLeft > 0
    readonly property bool paused: saved.pausedLeft > 0
    property real now: Date.now()
    readonly property real left: paused ? saved.pausedLeft : saved.endsAt - now
    readonly property string label: PlannerJs.remaining(left)

    function start(minutes: int): void {
        saved.pausedLeft = 0;
        saved.endsAt = Date.now() + minutes * 60000;
        now = Date.now();
    }

    function pause(): void {
        saved.pausedLeft = Math.max(1, saved.endsAt - Date.now());
        saved.endsAt = 0;
    }

    function resume(): void {
        saved.endsAt = Date.now() + saved.pausedLeft;
        saved.pausedLeft = 0;
        now = Date.now();
    }

    function cancel(): void {
        saved.endsAt = 0;
        saved.pausedLeft = 0;
    }

    PersistentProperties {
        id: saved
        reloadableId: "countdown"
        property real endsAt: 0      // ms since the epoch while running, else 0
        property real pausedLeft: 0  // ms left while paused, else 0
    }

    Timer {
        interval: 250 // often enough that the seconds don't skip
        running: saved.endsAt > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now();
            if (root.now >= saved.endsAt) {
                root.cancel();
                Notifications.send("Timer", "appointment-soon", "Time's up", "The timer has finished", true,
                                   ["string:sound-name:alarm-clock-elapsed"]);
            }
        }
    }
}
