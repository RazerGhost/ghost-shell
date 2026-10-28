import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import "../services/SnapLayout.js" as SnapLayout
import "../services/WindowGrid.js" as WindowGrid

// Snap Assist, like Windows: after you snap a window to a half or a third, the space next to it
// shows the other windows on that workspace, in a grid that fills it. Click one, or pick it with
// the arrow keys and Enter, to fill the space; Escape or a click elsewhere skips it.
Scope {
    id: root

    property bool open: false
    // The layout the picked window gets, and where it is (global logical pixels).
    property string layout
    property var area: ({ x: 0, y: 0, width: 0, height: 0 })
    property HyprlandMonitor monitor: null
    property HyprlandToplevel snappedWindow: null

    // The other windows on the snapped one's workspace, most recently used first.
    readonly property list<HyprlandToplevel> candidates: open
        ? Windows.recent.filter(t => t !== snappedWindow && t.workspace === snappedWindow?.workspace)
        : []

    function pick(window: HyprlandToplevel): void {
        open = false;
        Snap.snap(window, layout, true);
        Windows.focus(window);
    }

    Connections {
        target: Snap

        function onSnapped(window: HyprlandToplevel, layout: string): void {
            const rest = SnapLayout.complement(layout);
            if (rest === "")
                return;
            Hyprland.refreshToplevels(); // fresh focus order for the list
            root.snappedWindow = window;
            root.monitor = window.monitor;
            root.layout = rest;
            root.area = Snap.rect(window.monitor, rest);
            root.open = true;
        }
    }

    PanelWindow {
        id: panel

        // Nothing to offer: don't show an empty space.
        visible: root.open && root.candidates.length > 0
        screen: Quickshell.screens.find(s => s.name === root.monitor?.name) ?? null

        // Exactly over the empty space.
        anchors.top: true
        anchors.left: true
        margins.left: root.area.x - (root.monitor?.x ?? 0)
        margins.top: root.area.y - (root.monitor?.y ?? 0)
        implicitWidth: root.area.width
        implicitHeight: root.area.height
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-snap-assist"
        WlrLayershell.layer: WlrLayer.Overlay
        // OnDemand, not Exclusive: Hyprland refuses to focus windows while an exclusive surface
        // exists, which raced pick()'s focus call (see Switcher.qml).
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        HyprlandFocusGrab {
            windows: [panel]
            active: panel.visible
            onCleared: root.open = false
        }

        Rectangle {
            id: frame

            // The windows in a grid that fills the space and keeps their shapes (like the
            // overview). The selection starts on the most recently used one.
            readonly property var rows: WindowGrid.grid(
                root.candidates.map(t => ({ width: t.lastIpcObject?.size?.[0] ?? 1600, height: t.lastIpcObject?.size?.[1] ?? 1000 })),
                width - Theme.spacing.l * 2,
                height - title.height - Theme.spacing.l * 3,
                Theme.overview.gap, Theme.switcher.labelHeight)
            property int selected: 0

            anchors.fill: parent
            radius: Theme.radius.xl
            color: Colors.surfaceTranslucent
            focus: true

            // Arrow keys move the selection, Enter puts it in the space, Escape skips.
            Keys.onEscapePressed: root.open = false
            Keys.onPressed: event => {
                const directions = { [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down" };
                if (directions[event.key]) {
                    selected = WindowGrid.neighbour(rows, selected, directions[event.key]);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.candidates[selected])
                        root.pick(root.candidates[selected]);
                    event.accepted = true;
                }
            }

            Connections {
                target: root

                function onOpenChanged(): void {
                    frame.selected = 0;
                    frame.forceActiveFocus();
                }
            }

            Text {
                id: title
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.spacing.l
                text: "Pick a window for this space"
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.large
                font.weight: Font.DemiBold
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: title.y + title.height + Theme.spacing.l
                   + (parent.height - title.y - title.height - Theme.spacing.l * 2 - implicitHeight) / 2
                spacing: Theme.overview.gap

                Repeater {
                    model: frame.rows

                    Row {
                        id: row

                        required property var modelData

                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.overview.gap

                        Repeater {
                            model: row.modelData

                            MouseArea {
                                id: card

                                required property var modelData
                                readonly property HyprlandToplevel toplevel: root.candidates[modelData.index] ?? null

                                width: modelData.width
                                height: modelData.height + Theme.switcher.labelHeight
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: frame.selected = modelData.index
                                onClicked: root.pick(toplevel)

                                Accessible.role: Accessible.Button
                                Accessible.name: "Put " + (toplevel?.title ?? "") + " here"
                                Accessible.selected: frame.selected === modelData.index
                                Accessible.onPressAction: root.pick(toplevel)

                                WindowPreview {
                                    anchors.fill: parent
                                    toplevel: card.toplevel
                                    previewHeight: card.modelData.height
                                    highlighted: frame.selected === card.modelData.index
                                    capturing: panel.visible
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
