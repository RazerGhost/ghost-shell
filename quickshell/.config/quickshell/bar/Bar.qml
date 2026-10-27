import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.theme

// One bar per monitor: Variants creates a delegate for each entry in the model
// and destroys it when the monitor goes away.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property ShellScreen modelData
        screen: modelData

        // Width of the wider side pill. Both sides reserve this much, so the center pill
        // stays in the middle of the screen while the side pills grow outward.
        readonly property real side: Math.max(left.visible ? left.implicitWidth : 0, right.implicitWidth)
                                   + Theme.spacing.s

        // Anchoring only the top edge makes the layer surface horizontally centered and
        // as wide as its content, so the bar floats in the middle and grows outward.
        // The default exclusion mode (Auto) reserves space so windows tile below it.
        anchors.top: true
        margins.top: Theme.bar.gap
        implicitWidth: center.implicitWidth + side * 2
        implicitHeight: Theme.bar.height

        // Must be transparent from the start; only the pills draw a background.
        color: "transparent"

        // Only the pills take mouse input; clicks on the transparent space between and
        // around them go to the windows below.
        mask: Region {
            Region { item: left }
            Region { item: center }
            Region { item: right }
        }

        // Hyprland layer rules match on this (see hypr/rules.lua).
        WlrLayershell.namespace: "qs-bar"

        Pill {
            id: left
            anchors.right: center.left
            anchors.rightMargin: Theme.spacing.s
            visible: SystemTray.items.values.length > 0

            Tray {}
        }

        Pill {
            id: center
            anchors.centerIn: parent

            Workspaces {
                screen: window.modelData
            }

            Clock {}
        }

        Pill {
            id: right
            anchors.left: center.right
            anchors.leftMargin: Theme.spacing.s
            // The icons have their own padding (for the hover highlight), so less row spacing.
            spacing: Theme.spacing.xs

            Network {}
            BluetoothStatus {}
            Volume {}
            PowerMode {}
            Battery {}
        }
    }
}
