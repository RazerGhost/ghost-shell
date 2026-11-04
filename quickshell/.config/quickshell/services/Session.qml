// Locking and ending the session: the power menu and the idle steps go through here.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // lock/Lock.qml locks the screen when this fires. `grace`: the idle lock, which a touch
    // within Settings -> Lock screen -> Grace period undoes without the password.
    signal lockRequested(bool grace)
    // idle/Idle.qml turns the screen off once you stop touching it.
    signal screenOffRequested()
    // The screen is locked (kept up to date by lock/Lock.qml), e.g. for a video wallpaper to
    // pause behind the lock screen.
    property bool locked: false

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

    // hyprshutdown closes apps gracefully first, when it's installed; otherwise Hyprland exits.
    function logout(): void {
        Quickshell.execDetached(["sh", "-c",
            "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
