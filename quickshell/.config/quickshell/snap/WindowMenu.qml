import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme

// The window menu (Alt+Space or Super+Z), a card at the top of the focused window, so it's clear
// which window it's about: its title bar actions and workspace (WindowActions.qml), and the snap
// layouts, Windows 11 style (SnapLayouts.qml). Super+Left/Right snap to halves directly.
Scope {
    id: root

    property bool open: false
    // The window the menu is about: the one focused when it opened.
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
            Snap.snap(Windows.active, layout, false);
        }

        // qs ipc call snap down (Super+Down): un-snap the focused window, or minimize it.
        function down(): void {
            Snap.restoreOrMinimize(Windows.active);
        }

        // qs ipc call snap picker: show or hide the window menu for the focused window.
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
        // The keyboard, for Escape. OnDemand, not Exclusive: minimizing focuses the next window
        // as the menu closes, which an exclusive surface would refuse (see the switcher).
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // Closes the menu when you click anywhere else.
        HyprlandFocusGrab {
            windows: [window]
            active: window.visible
            onCleared: root.open = false
        }

        Rectangle {
            id: card

            implicitWidth: menu.implicitWidth + Theme.spacing.l * 2
            implicitHeight: menu.implicitHeight + Theme.spacing.l * 2
            radius: Theme.radius.xl
            color: Colors.surfaceTranslucent
            focus: true
            Keys.onEscapePressed: root.open = false

            Column {
                id: menu
                anchors.centerIn: parent
                spacing: Theme.spacing.l

                WindowActions {
                    width: layouts.implicitWidth
                    target: root.target
                    onDone: root.open = false
                }

                SnapLayouts {
                    id: layouts
                    target: root.target
                    onDone: root.open = false
                }
            }
        }
    }
}
