import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme

// The wallpaper picker: its own strip across the top of the focused screen, under the island
// (user's choice; it used to stretch the island itself). Opened from quick settings' wallpaper
// button or `qs ipc call wallpaper picker`; arrow keys and Enter pick one, Escape or a click
// elsewhere closes it.
Scope {
    PanelWindow {
        id: window

        visible: Wallpaper.pickerOpen
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        anchors.top: true
        anchors.left: true
        anchors.right: true
        margins.top: Theme.island.height + Theme.spacing.s
        margins.left: Theme.spacing.l
        margins.right: Theme.spacing.l
        implicitHeight: panel.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-wallpaper-picker"
        WlrLayershell.layer: WlrLayer.Top
        // For Escape. On demand, like the island's menus.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // Closes the strip when you click anywhere else.
        HyprlandFocusGrab {
            windows: [window]
            active: window.visible
            onCleared: Wallpaper.pickerOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.xl
            color: Colors.surfaceTranslucent
            focus: true
            Keys.onEscapePressed: Wallpaper.pickerOpen = false
            Keys.onPressed: event => panel.handleKey(event)

            WallpaperPanel {
                id: panel
                width: parent.width
                topPadding: Theme.spacing.l
                active: Wallpaper.pickerOpen
            }
        }
    }
}
