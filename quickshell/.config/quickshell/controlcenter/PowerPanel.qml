import QtQuick
import qs.services
import qs.theme

// The power menu (power button in quick settings, or Ctrl+Alt+Delete): lock (or lock and turn
// off the screen), suspend, log out, restart and shut down. One click each: log out, restart and
// shut down give a few seconds to change your mind on the screen that follows
// (lock/SessionEnd.qml: Cancel or Escape), so they no longer ask for a second click here.
Column {
    id: root

    // An action ran; the island closes the menu.
    signal done()

    function run(action: var): void {
        done();
        Session[action.run]();
    }

    // `run` is the Session function that does it.
    readonly property var actions: [
        { name: "Lock", icon: "lock", run: "lock" },
        { name: "Lock and turn off the screen", icon: "desktop_access_disabled", run: "lockScreenOff" },
        { name: "Suspend", icon: "bedtime", run: "suspend" },
        { name: "Log out", icon: "logout", run: "logout" },
        { name: "Restart", icon: "restart_alt", run: "reboot" },
        { name: "Shut down", icon: "power_settings_new", run: "poweroff" }
    ]

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.xs

    Repeater {
        model: root.actions

        ListRow {
            required property var modelData

            width: root.width - root.leftPadding - root.rightPadding
            icon: modelData.icon
            title: modelData.name
            onActivated: root.run(modelData)
        }
    }
}
