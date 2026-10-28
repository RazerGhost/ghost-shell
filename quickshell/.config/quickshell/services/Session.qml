// Locking and ending the session: the power menu, the idle steps and the login screen's power
// buttons all go through here.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // lock/Lock.qml locks the screen when this fires.
    signal lockRequested()

    function lock(): void {
        lockRequested();
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
