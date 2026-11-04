// Locking and ending the session: the power menu and the idle steps go through here.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../bar/Greeting.js" as Greeting

Singleton {
    id: root

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
                const first = Greeting.firstName(text);
                if (first !== "")
                    root.userName = first;
            }
        }
    }

    // Logging out, restarting or shutting down ("logout", "reboot", "poweroff"; "" otherwise):
    // lock/SessionEnd.qml asks every app to close first, then calls finish(). cancel() stops it
    // (an app asked to save something). Kept across a shell reload, so a reload while the apps
    // close doesn't drop the shutdown halfway (a crash still does: the restarted shell starts
    // afresh).
    property alias ending: kept.ending

    PersistentProperties {
        id: kept
        reloadableId: "sessionEnding"

        property string ending: ""
    }

    // Does it, once. A refused restart or shutdown (another app holding it off, polkit) brings
    // the desktop back and says so, rather than leaving the screen waiting.
    function finish(): void {
        if (ender.running)
            return;
        ender.command = ({
            logout: ["hyprctl", "dispatch", "hl.dsp.exit()"],
            reboot: ["systemctl", "reboot"],
            poweroff: ["systemctl", "poweroff"]
        })[ending] ?? [];
        if (ender.command.length > 0)
            ender.running = true;
    }

    Process {
        id: ender
        onExited: code => {
            if (code === 0)
                return;
            const what = root.ending === "reboot" ? "restart" : root.ending === "poweroff" ? "shut down" : "log out";
            root.cancel();
            Notifications.send("Session", "dialog-warning", "Couldn't " + what,
                               "Something held it off. Try again, or close what's still running.", false, []);
        }
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
