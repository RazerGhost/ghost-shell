import QtQuick
import Quickshell
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

        // Anchoring only the top edge makes the layer surface horizontally centered and
        // as wide as its content, so the bar floats in the middle and grows outward.
        // The default exclusion mode (Auto) reserves space so windows tile below it.
        anchors.top: true
        margins.top: Theme.bar.gap
        implicitWidth: center.implicitWidth
        implicitHeight: Theme.bar.height

        // Must be transparent from the start; only the pills draw a background.
        color: "transparent"

        // Hyprland layer rules match on this (see hypr/rules.lua).
        WlrLayershell.namespace: "qs-bar"

        // Phase 2 adds pills on either side of this one.
        Pill {
            id: center
            anchors.centerIn: parent

            Workspaces {
                screen: window.modelData
            }

            Clock {}
        }
    }
}
