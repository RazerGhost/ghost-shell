// Night light through hyprsunset: warmer colors to go easy on the eyes in the evening.
//
// The quick settings tile turns it on and off; with a schedule (Settings) it also turns
// on at the start time and off at the end time. Toggling in between lasts until the next of
// those. hyprsunset can't report whether it's on (only the last temperature it was given), so
// the state lives here, and the shell sets hyprsunset to match when it starts.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Schedule.js" as Schedule

Singleton {
    id: root

    property bool on: false
    readonly property int temperature: Settings.values.nightLightTemperature

    // Whether the schedule says on right now (false without a schedule).
    readonly property bool scheduledOn: Settings.values.nightLightScheduled
        && Schedule.active(Schedule.minutesOf(clock.date), Settings.values.nightLightStart, Settings.values.nightLightEnd)

    function toggle(): void {
        set(!on);
    }

    function set(value: bool): void {
        on = value;
        retry.attempts = 0;
        apply.running = false;
        apply.running = true;
    }

    // Reaching the start or end time, or changing the schedule, switches it.
    onScheduledOnChanged: set(scheduledOn)
    // A new temperature applies right away while it's on.
    onTemperatureChanged: {
        if (on)
            set(true);
    }

    // At startup, follow the schedule (off without one).
    Component.onCompleted: set(scheduledOn)

    // Tells hyprsunset. It starts alongside the shell at login and may not be up yet: until it
    // answers "ok", try again every second (for half a minute).
    Process {
        id: apply
        command: root.on ? ["hyprctl", "hyprsunset", "temperature", String(root.temperature)]
                         : ["hyprctl", "hyprsunset", "identity"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "ok" && retry.attempts < 30)
                    retry.start();
            }
        }
    }

    Timer {
        id: retry
        property int attempts: 0
        interval: 1000
        onTriggered: {
            attempts++;
            apply.running = true;
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
