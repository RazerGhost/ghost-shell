import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// Alt+Tab, Windows style: every window with a live preview, most recently used first. Hold Alt
// and tap Tab (Shift+Tab goes back); let go of Alt to switch to the selected window. Escape or a
// click elsewhere cancels; clicking a preview switches to it. The Tab presses come from Hyprland
// binds (`qs ipc call switcher next`); the Alt release comes to the switcher itself, which has
// the keyboard while it's open.
Scope {
    id: root

    property bool open: false
    property int index: 0

    // Most recently used first; the order is refreshed when the switcher opens.
    readonly property list<HyprlandToplevel> windows: Windows.recent

    function step(delta: int): void {
        if (!open) {
            Hyprland.refreshToplevels();
            index = 0;
            open = true;
        }
        if (windows.length > 0)
            index = (index + delta + windows.length) % windows.length;
    }

    function commit(): void {
        const window = windows[index];
        open = false;
        if (!window)
            return;
        Windows.show(window);
    }

    IpcHandler {
        target: "switcher"

        // Alt+Tab: open on the previous window, or move one further.
        function next(): void {
            root.step(1);
        }

        // Alt+Shift+Tab: move one back.
        function previous(): void {
            root.step(-1);
        }
    }

    PanelWindow {
        id: window

        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        // No anchors: the compositor centers it.
        implicitWidth: Math.min(list.contentWidth, (screen?.width ?? 1920) * 0.9) + Theme.spacing.l * 2
        implicitHeight: Theme.switcher.thumbHeight + Theme.switcher.labelHeight + Theme.spacing.l * 2
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-switcher"
        WlrLayershell.layer: WlrLayer.Overlay
        // The keyboard, so the switcher sees Alt being released: an OnDemand surface gets it when
        // it appears. Not Exclusive: while an exclusive surface exists Hyprland refuses to focus
        // any window, and closing the switcher raced the focus call, so Alt+Tab often left the
        // old window focused (with the new one only raised).
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        HyprlandFocusGrab {
            windows: [window]
            active: window.visible
            onCleared: root.open = false
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.xl
            color: Colors.surfaceTranslucent
            focus: true

            Keys.onReleased: event => {
                if (event.key === Qt.Key_Alt)
                    root.commit();
            }
            Keys.onEscapePressed: root.open = false
            Keys.onReturnPressed: root.commit()

            ListView {
                id: list

                anchors.fill: parent
                anchors.margins: Theme.spacing.l
                orientation: ListView.Horizontal
                spacing: Theme.spacing.m
                // ScriptModel: a window opening or closing doesn't rebuild every live preview.
                model: ScriptModel { values: root.open ? [...root.windows] : [] }
                currentIndex: root.index
                highlightMoveDuration: Theme.anim.fast
                boundsBehavior: Flickable.StopAtBounds

                Accessible.role: Accessible.List
                Accessible.name: "Windows"

                delegate: MouseArea {
                    id: card

                    required property HyprlandToplevel modelData
                    required property int index
                    readonly property bool selected: index === root.index
                    // The window's own shape, like in the overview (16:10 until its size is known),
                    // capped so a very wide window doesn't take the whole row.
                    readonly property var size: modelData.lastIpcObject?.size
                    readonly property real aspect: size ? size[0] / size[1] : 16 / 10

                    width: Theme.switcher.thumbHeight * Math.min(aspect, Theme.switcher.maxAspect)
                    height: ListView.view.height
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.index = index
                    onClicked: root.commit()

                    Accessible.role: Accessible.ListItem
                    Accessible.name: modelData.title
                    Accessible.selected: selected

                    // Only captured while the switcher is open.
                    WindowPreview {
                        anchors.fill: parent
                        toplevel: card.modelData
                        previewHeight: Theme.switcher.thumbHeight
                        highlighted: card.selected
                        capturing: root.open
                        closable: true
                    }
                }
            }
        }
    }
}
