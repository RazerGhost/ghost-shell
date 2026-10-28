import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme

// Snapping, Windows 11 style. Super+Z shows the layouts in a small card at the top of the
// focused window (so it's clear which window moves); Super+Left/Right snap to halves directly.
Scope {
    id: root

    property bool open: false
    // The window being snapped: the one focused when the picker opened.
    property HyprlandToplevel target: null

    // Hyprland's latest details for the window: position and size, [x, y] in global coordinates.
    readonly property var at: target?.lastIpcObject?.at ?? [0, 0]
    readonly property var size: target?.lastIpcObject?.size ?? [0, 0]
    readonly property HyprlandMonitor monitor: target?.monitor ?? null

    function toggle(): void {
        if (open) {
            open = false;
            return;
        }
        target = Windows.active;
        if (!target)
            return;
        Hyprland.refreshToplevels(); // fresh position and size for placing the card
        open = true;
    }

    IpcHandler {
        target: "snap"

        // qs ipc call snap active left (or right, top-left, left-third, ...): snap the focused window.
        function active(layout: string): void {
            Snap.snap(Windows.active, layout);
        }

        // qs ipc call snap picker: show or hide the layouts for the focused window.
        function picker(): void {
            root.toggle();
        }
    }

    PanelWindow {
        id: window

        visible: root.open
        screen: Quickshell.screens.find(s => s.name === root.monitor?.name) ?? null

        // Top center of the target window, kept inside the screen.
        anchors.top: true
        anchors.left: true
        margins.left: Math.max(Theme.spacing.m, Math.min((screen?.width ?? 0) - width - Theme.spacing.m,
                      root.at[0] - (root.monitor?.x ?? 0) + (root.size[0] - width) / 2))
        margins.top: Math.max(Theme.island.height + Theme.spacing.s, root.at[1] - (root.monitor?.y ?? 0) + Theme.spacing.m)
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-snap"
        WlrLayershell.layer: WlrLayer.Overlay
        // Take the keyboard while open, for Escape.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Closes the picker when you click anywhere else.
        HyprlandFocusGrab {
            windows: [window]
            active: window.visible
            onCleared: root.open = false
        }

        Rectangle {
            id: card

            implicitWidth: layouts.implicitWidth + Theme.spacing.l * 2
            implicitHeight: layouts.implicitHeight + Theme.spacing.l * 2
            radius: Theme.radius.xl
            color: Colors.surfaceTranslucent
            focus: true
            Keys.onEscapePressed: root.open = false

            SnapLayouts {
                id: layouts
                anchors.centerIn: parent
                target: root.target
                onDone: root.open = false
            }
        }
    }
}
