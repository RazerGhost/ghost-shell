import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import "../services/SnapLayout.js" as SnapLayout

// Snap Assist, like Windows: after you snap a window to a half or a third, the space next to it
// shows the other windows on that workspace. Click one to fill the space; Escape or a click
// elsewhere skips it.
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
            anchors.fill: parent
            radius: Theme.radius.xl
            color: Colors.surfaceTranslucent
            focus: true
            Keys.onEscapePressed: root.open = false

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

            // The windows, as many per row as fit; scrolls when there are more.
            Flickable {
                anchors.top: title.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacing.l
                contentHeight: flow.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: flow
                    width: parent.width
                    spacing: Theme.spacing.m

                    Repeater {
                        model: root.candidates

                        MouseArea {
                            id: card

                            required property HyprlandToplevel modelData

                            width: Theme.switcher.thumbHeight * 16 / 10
                            height: Theme.switcher.thumbHeight + Theme.switcher.labelHeight
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pick(modelData)

                            Accessible.role: Accessible.Button
                            Accessible.name: "Put " + modelData.title + " here"
                            Accessible.onPressAction: root.pick(modelData)

                            WindowPreview {
                                anchors.fill: parent
                                toplevel: card.modelData
                                highlighted: card.containsMouse
                                capturing: panel.visible
                            }
                        }
                    }
                }
            }
        }
    }
}
