// Locking and ending the session: the power menu and the idle steps go through here.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    // lock/Lock.qml locks the screen when this fires. `grace`: the idle lock, which a touch
    // within Settings -> Lock screen -> Grace period undoes without the password.
    signal lockRequested(bool grace)
    // idle/Idle.qml turns the screen off once you stop touching it.
    signal screenOffRequested()
    // The screen is locked (kept up to date by lock/Lock.qml), e.g. for a video wallpaper to
    // pause behind the lock screen.
    property bool locked: false
    // The lock screen let you in: `first` for the lock this session started with (the login), else
    // an unlock later on. The island greets you (bar/Island.qml).
    signal unlocked(bool first)

    // Your name for greetings: the first part of your account's full name, else the user name.
    property string userName: Quickshell.env("USER") ?? ""

    Process {
        running: true
        command: ["getent", "passwd", Quickshell.env("USER") ?? ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const full = (text.split(":")[4] ?? "").split(",")[0].trim();
                if (full !== "")
                    userName = full.split(" ")[0];
            }
        }
    }

    // Logging out, restarting or shutting down ("logout", "reboot", "poweroff"; "" otherwise):
    // lock/SessionEnd.qml asks every app to close first, then calls finish(). cancel() stops it
    // (an app asked to save something).
    property string ending: ""

    function finish(): void {
        const action = ending;
        if (action === "logout")
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]);
        else if (action === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"]);
        else if (action === "poweroff")
            Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function cancel(): void {
        ending = "";
    }

    function lock(): void {
        lockRequested(false);
    }

    function idleLock(): void {
        lockRequested(true);
    }

    // The power menu's "Lock and turn off the screen".
    function lockScreenOff(): void {
        lockRequested(false);
        screenOffRequested();
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function logout(): void {
        ending = "logout";
    }

    function reboot(): void {
        ending = "reboot";
    }

    function poweroff(): void {
        ending = "poweroff";
    }
}
