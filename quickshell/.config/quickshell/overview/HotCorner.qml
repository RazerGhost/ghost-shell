import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services

// The hot corner, like GNOME's: resting the pointer in the top-left corner of a screen opens the
// overview (Settings -> Windows; on by default). A short delay keeps a pointer that merely passes
// through from opening it, and it's off while a window is fullscreen there (games).
Scope {
    id: root

    signal triggered()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: corner

            required property ShellScreen modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            // fullscreen 2 is real fullscreen; 1 (maximized) keeps the corner.
            readonly property bool fullscreen: (monitor?.activeWorkspace?.toplevels.values ?? [])
                .some(t => t.lastIpcObject?.fullscreen === 2)

            screen: modelData
            visible: Settings.values.hotCorner && !fullscreen
            anchors.top: true
            anchors.left: true
            implicitWidth: 2
            implicitHeight: 2
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "qs-hot-corner"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: delay.restart()
                onExited: delay.stop()
            }

            Timer {
                id: delay
                interval: 150
                onTriggered: root.triggered()
            }
        }
    }
}
