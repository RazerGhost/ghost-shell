// Focus mode (quick settings' round button, the today menu's timer part, `qs ipc call focus
// toggle`): a timer of 15, 25 or 50 minutes (the today menu's, shown in the island; the button
// starts the length used last, `focusMinutes`), pop-ups held back like Do Not Disturb (critical
// ones and apps set to "Always pop up" still show; one notification says how many came in when
// it ends), and the desktop widgets hidden. It lasts as long as the timer: it ends when time's
// up, when the timer is cancelled, or from the button (which also cancels the timer it
// started). A timer already running is used as it is. Hyprland's bell for apps is quiet too
// (settings/HyprlandSettings.qml). The lock screen still shows the widgets: it's the desktop,
// locked, where nobody is working.
// When its time is up, a notification offers a 5-minute break (a timer of its own, "Break" in
// the island) or another session; when a break is up, another session. Kept across shell
// reloads, like the timer.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool on: saved.on
    readonly property int minutes: Settings.values.focusMinutes ?? 25
    readonly property var lengths: [15, 25, 50]
    readonly property int breakMinutes: 5
    // The running timer is a break started from the notification.
    readonly property bool onBreak: Countdown.active && saved.breakTimer === Countdown.runs
    // The running timer is this session's own (Countdown.runs of it), for Countdown: its end is
    // announced here instead.
    function owns(runs: int): bool {
        return (saved.on && saved.timer === runs) || saved.breakTimer === runs;
    }

    function start(length: int): void {
        if (saved.on)
            return; // already in a session (an old "Focus again" from the history)
        Settings.values.focusMinutes = length;
        if (!Countdown.active || onBreak) {
            Countdown.run(length);
            saved.timer = Countdown.runs;
        } else {
            saved.timer = -1;
        }
        saved.breakTimer = -1;
        saved.on = true;
    }

    function stop(): void {
        saved.on = false;
        // Only the timer it started: not one already running, or one started over it since.
        if (Countdown.active && Countdown.runs === saved.timer)
            Countdown.cancel();
        saved.timer = -1;
    }

    // Countdown's timer of this session (or its break) reached zero. The notification waits for
    // its button in a process of its own (notify-send prints the one pressed), which answers
    // through `qs ipc call focus …`: each ending gets its own, and the buttons still work after
    // a shell reload (a Process of the shell's was killed with it). Normal urgency: critical's
    // error red read as a failure.
    function timeUp(runs: int): void {
        const wasBreak = saved.breakTimer === runs;
        saved.breakTimer = -1;
        Quickshell.execDetached(["sh", "-c", `
            choice=$(notify-send --app-name=Focus --icon=appointment-soon --urgency=normal \
                --hint=string:sound-name:alarm-clock-elapsed "$@")
            case $choice in
                break) qs ipc call focus takeBreak ;;
                again) qs ipc call focus again ;;
            esac`, "sh",
            ...(wasBreak ? [] : ["--action=break=Take a " + breakMinutes + "-minute break"]),
            "--action=again=Focus again",
            wasBreak ? "Break's over" : "Focus time is over",
            wasBreak ? "Ready for another " + minutes + " minutes?" : "Well done. Time for a short break?"]);
    }

    function takeBreak(): void {
        if (Countdown.active) {
            Notifications.send("Focus", "appointment-soon", "No break started", "A timer is already running.", false, []);
            return;
        }
        Countdown.run(breakMinutes);
        saved.breakTimer = Countdown.runs;
    }

    PersistentProperties {
        id: saved
        reloadableId: "focus"
        property bool on: false
        property int timer: -1      // Countdown.runs of the timer it started, else -1
        property int breakTimer: -1 // Countdown.runs of the break it started, else -1
    }



    IpcHandler {
        target: "focus"

        function toggle(): void {
            root.on ? root.stop() : root.start(root.minutes);
        }

        // The buttons of the notification at a session's or a break's end (timeUp).
        function takeBreak(): void {
            root.takeBreak();
        }

        function again(): void {
            root.start(root.minutes);
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
