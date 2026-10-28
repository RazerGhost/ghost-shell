import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme

// Draws the chosen wallpaper (services/Wallpaper.qml) behind everything on every monitor.
// A new one fades in over the old one.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property ShellScreen modelData
        screen: modelData
        // Until a wallpaper is chosen, Hyprland's default shows instead.
        visible: Wallpaper.path !== ""

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "black"

        WlrLayershell.namespace: "qs-wallpaper"
        WlrLayershell.layer: WlrLayer.Background

        // The previous wallpaper stays under the new one until the new one has faded in.
        Image {
            id: previous
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(window.width, window.height)
        }

        Image {
            id: current

            anchors.fill: parent
            source: Wallpaper.path ? "file://" + Wallpaper.path : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            // Decode at the screen's size, not the picture's (a 6K photo would use ~100 MB).
            sourceSize: Qt.size(window.width, window.height)
            opacity: 0

            onStatusChanged: {
                if (status === Image.Ready)
                    fadeIn.restart();
            }

            NumberAnimation {
                id: fadeIn
                target: current
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.anim.morph
                onFinished: previous.source = current.source
            }
        }
    }
}
