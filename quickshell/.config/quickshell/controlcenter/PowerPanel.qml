import QtQuick
import qs.services
import qs.theme

// The power menu (power button in quick settings, or Ctrl+Alt+Delete): lock, suspend, log out,
// restart and shut down. The last three end the session, so they ask for a second click.
Column {
    id: root

    // The action waiting for its confirming click, or "".
    property string armed: ""

    // An action ran; the island closes the menu.
    signal done()

    function run(action: var): void {
        if (action.confirm && armed !== action.name) {
            armed = action.name;
            disarm.restart();
            return;
        }
        armed = "";
        done();
        Session[action.run]();
    }

    // `run` is the Session function that does it.
    readonly property var actions: [
        { name: "Lock", icon: "lock", run: "lock", confirm: false },
        { name: "Suspend", icon: "bedtime", run: "suspend", confirm: false },
        { name: "Log out", icon: "logout", run: "logout", confirm: true },
        { name: "Restart", icon: "restart_alt", run: "reboot", confirm: true },
        { name: "Shut down", icon: "power_settings_new", run: "poweroff", confirm: true }
    ]

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.xs

    onVisibleChanged: armed = ""

    Timer {
        id: disarm
        interval: 4000
        onTriggered: root.armed = ""
    }

    Repeater {
        model: root.actions

        ListRow {
            required property var modelData

            width: root.width - root.leftPadding - root.rightPadding
            icon: modelData.icon
            title: modelData.name
            subtitle: root.armed === modelData.name ? "Click again to confirm" : ""
            highlighted: root.armed === modelData.name
            onActivated: root.run(modelData)
        }
    }
}
