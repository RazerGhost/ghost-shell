import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import "../services/SnapLayout.js" as SnapLayout

// The window menu (Alt+Space or Super+Z), a card at the top of the focused window, so it's clear
// which window it's about: its title bar actions and workspace (WindowActions.qml), and the snap
// layouts, Windows 11 style (SnapLayouts.qml), which arrange the tiled windows around it.
// Super+Left/Right snap to halves directly.
Scope {
    id: root

    property bool open: false
    // The window the menu is about: the one focused when it opened.
    property HyprlandToplevel target: null

    // Hyprland's latest details for the window: position and size, [x, y] in global coordinates.
    readonly property var at: target?.lastIpcObject?.at ?? [0, 0]
    readonly property var size: target?.lastIpcObject?.size ?? [0, 0]
    readonly property HyprlandMonitor monitor: target?.monitor ?? null

    // Super+Up / Down: from the spot the window was snapped to, if it's still there (a window
    // swapped, dragged or floated since isn't: SnapLayout.holds); Hyprland's view of the window is
    // asked for first, a moment before (its last answer can be old).
    function step(direction: string): void {
        const window = Windows.active;
        if (!window)
            return;
        Hyprland.refreshToplevels();
        stepLater.window = window;
        stepLater.direction = direction;
        stepLater.restart();
    }

    Timer {
        id: stepLater
        property HyprlandToplevel window: null
        property string direction
        interval: Theme.snap.refreshWait
        onTriggered: {
            const ipc = window?.lastIpcObject;
            const monitor = window?.monitor;
            if (!ipc || !monitor)
                return;
            const box = ipc.floating ? null : { x: ipc.at[0], y: ipc.at[1], w: ipc.size[0], h: ipc.size[1] };
            const area = { x: monitor.x, y: monitor.y, w: monitor.width / monitor.scale, h: monitor.height / monitor.scale };
            const spot = Snap.spotOf(window);
            const next = SnapLayout.holds(spot, box, area) ? SnapLayout.nextSpot(spot, direction) : null;
            if (next)
                Snap.snap(window, next);
            else if (direction === "up")
                Windows.run(window, "fullscreen", `mode = "maximized", action = "toggle"`);
            else
                Windows.minimize(window);
            window = null;
        }
    }

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

        // qs ipc call snap up (Super+Up): a window snapped to a half goes to its top quarter, a
        // bottom quarter back to its half (Windows 11); anything else maximizes.
        function up(): void {
            root.step("up");
        }

        // qs ipc call snap down (Super+Down): a half to its bottom quarter, a top quarter back to
        // its half; anything else minimizes.
        function down(): void {
            root.step("down");
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
        margins.top: Math.max(Theme.island.reserved + Theme.spacing.s, root.at[1] - (root.monitor?.y ?? 0) + Theme.spacing.m)
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-snap"

        // Blur behind the card (ext-background-effect; see NOTES.md).
        BackgroundEffect.blurRegion: Region { item: card; radius: card.radius }

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

        Surface {
            id: card

            implicitWidth: menu.implicitWidth + Theme.spacing.l * 2
            implicitHeight: menu.implicitHeight + Theme.spacing.l * 2
            radius: Theme.radius.l
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
