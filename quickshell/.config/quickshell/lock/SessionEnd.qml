import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets
import "SessionEnd.js" as SessionEndJs

// Logging out, restarting or shutting down (the power menu; Session.ending): the screens dim and
// say what's happening, every app is asked to close (so it can save, like closing its window),
// and once they're gone it goes ahead (Session.finish). An app that doesn't close within a few
// seconds (asking whether to save, or stuck) is listed: show it to answer it (which stops the
// shutdown), go ahead anyway, or cancel (Escape).
Scope {
    id: root

    readonly property string action: Session.ending
    readonly property bool active: action !== ""
    // The windows still open, the shell's own left out (its windows close with it).
    readonly property var remaining: Hyprland.toplevels.values.filter(w => (w.wayland?.appId ?? "") !== "org.quickshell")
    // Waited long enough; while apps are still open then, they're listed (and go off the list as
    // they close, or come back on it when one opens a "save?" window).
    property bool waited: false
    readonly property bool stuck: active && waited && remaining.length > 0
    // How many there were to close, for "2 of 5 closed"; more when an app opens another window.
    property int started: 0
    onRemainingChanged: {
        if (active)
            started = Math.max(started, remaining.length);
    }

    readonly property var words: ({
        logout:   { title: "Logging out",   icon: "logout",             anyway: "Log out anyway" },
        reboot:   { title: "Restarting",    icon: "restart_alt",        anyway: "Restart anyway" },
        poweroff: { title: "Shutting down", icon: "power_settings_new", anyway: "Shut down anyway" }
    })[action] ?? { title: "", icon: "power_settings_new", anyway: "" }

    onActiveChanged: begin()
    // A shell reload while the apps close comes back with `ending` still set (Session.qml).
    Component.onCompleted: begin()

    function begin(): void {
        waited = false;
        if (!active)
            return;
        started = remaining.length;
        for (const window of remaining)
            Windows.close(window);
        patience.restart();
    }

    // Everything closed: a moment more, so the screen is seen, then go ahead.
    readonly property bool allClosed: active && remaining.length === 0
    onAllClosedChanged: {
        if (allClosed)
            go.restart();
    }

    Timer {
        id: go
        interval: Theme.session.settle
        onTriggered: {
            if (root.allClosed)
                Session.finish();
        }
    }

    Timer {
        id: patience
        interval: Theme.session.patience
        onTriggered: root.waited = true
    }

    // Stops, then brings the window forward to be answered, a moment later: right away, the
    // dimmed screen's hold on the keyboard hadn't reached Hyprland yet, which then raised the
    // window without focusing it (the switcher's race, NOTES).
    function showWindow(window: HyprlandToplevel): void {
        Session.cancel();
        showLater.window = window;
        showLater.restart();
    }

    Timer {
        id: showLater
        property HyprlandToplevel window: null
        interval: Theme.session.release
        onTriggered: {
            if (window)
                Windows.show(window);
            window = null;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData
            readonly property bool focused: (Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name) === modelData.name

            screen: modelData
            visible: root.active || shade.opacity > 0
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-session-end"
            // Exclusive: the keyboard (Escape) goes here (OnDemand never got it, checked). Hyprland
            // won't focus a window while it's there, so "Show it" lets go first (showWindow).
            WlrLayershell.keyboardFocus: root.active && focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Rectangle {
                id: shade
                anchors.fill: parent
                color: Colors.m3surface
                opacity: root.active ? Theme.session.shade : 0
                Behavior on opacity { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }

                // Clicks stop here, not on what's under it.
                MouseArea {
                    anchors.fill: parent
                }
            }

            Column {
                id: body
                anchors.centerIn: parent
                width: Theme.session.width
                visible: window.focused
                opacity: root.active ? 1 : 0
                scale: root.active ? 1 : 0.94
                spacing: Theme.spacing.l
                Behavior on opacity { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
                Behavior on scale { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }

                focus: true
                Keys.onEscapePressed: Session.cancel()

                // The action's icon in a ring that turns while apps close.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.session.ring
                    height: width

                    ProgressRing {
                        anchors.fill: parent
                        value: Theme.session.arc
                        visible: !root.stuck

                        // Still while animations are off.
                        RotationAnimation on rotation {
                            running: root.active && !root.stuck && Theme.session.turn > 0
                            from: 0
                            to: 360
                            loops: Animation.Infinite
                            duration: Theme.session.turn
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        icon: root.stuck ? "hourglass_top" : root.words.icon
                        color: Colors.m3primary
                        font.pixelSize: Theme.session.icon
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.words.title
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.title
                    font.weight: Font.DemiBold
                    Accessible.role: Accessible.AlertMessage
                    Accessible.name: text
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: SessionEndJs.message(root.started, root.remaining.length, root.stuck)
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }

                // The apps still open: click one to stop and answer it.
                Column {
                    width: parent.width
                    visible: root.stuck
                    spacing: Theme.spacing.xs

                    Repeater {
                        model: root.stuck ? root.remaining : []

                        ListRow {
                            required property HyprlandToplevel modelData
                            width: parent.width
                            appIcon: Windows.iconFor(modelData)
                            title: modelData.title || (modelData.wayland?.appId ?? "")
                            subtitle: "Show it"
                            onActivated: root.showWindow(modelData)
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacing.s

                    TextButton {
                        text: "Cancel"
                        onClicked: Session.cancel()
                    }

                    TextButton {
                        visible: root.stuck
                        filled: true
                        text: root.words.anyway
                        onClicked: Session.finish()
                    }
                }
            }
        }
    }
}
