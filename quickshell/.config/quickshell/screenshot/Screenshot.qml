import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// Screenshots, like Windows' Snipping Tool (user's choice). Super+Shift+S freezes the focused
// monitor and dims it; a bar at the top picks Region (drag a rectangle), Window (click one) or
// Screen (click anywhere). Escape cancels. Print Screen takes the whole screen at once.
// Every screenshot is saved to ~/Pictures/Screenshots, copied to the clipboard, and announced
// with a notification showing it (click it to open the picture).
//
// The frozen picture is one frame from ScreencopyView, and the screenshot is cut from that same
// frame, so it shows exactly what was frozen (an open menu or tooltip included).
Scope {
    id: root

    property bool open: false
    property string mode: "region" // "region", "window" or "screen"
    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Screenshots"

    function start(withMode: string): void {
        mode = withMode;
        Hyprland.refreshToplevels(); // fresh window positions for Window mode
        open = true;
    }

    // Saves the picture and tells the user; `path` is where grabToImage wrote it.
    function done(path: string): void {
        open = false;
        Quickshell.execDetached(["sh", "-c", `
            wl-copy --type image/png < "$1"
            action=$(notify-send -a Screenshot -i "$1" -A default=Open "Screenshot saved" "Copied to the clipboard, and saved in Pictures/Screenshots")
            [ "$action" = default ] && xdg-open "$1"
        `, "sh", path]);
    }

    function fileName(): string {
        return folder + "/Screenshot_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png";
    }

    IpcHandler {
        target: "screenshot"

        // Super+Shift+S: the overlay, starting in Region mode.
        function region(): void {
            root.start("region");
        }

        // Print Screen: the whole focused monitor, without the overlay.
        function screen(): void {
            root.start("screen");
            capture.immediate = true;
        }
    }

    // The folder has to exist before a picture is saved into it.
    Process {
        running: true
        command: ["mkdir", "-p", root.folder]
    }

    PanelWindow {
        id: capture

        // Print Screen: take the shot as soon as the frame is frozen, without showing anything.
        property bool immediate: false

        readonly property HyprlandMonitor monitor: Hyprland.focusedMonitor
        // The selection, in this window's coordinates.
        property rect selection: Qt.rect(0, 0, 0, 0)

        // The window under the pointer in Window mode: the most recently used one there (the
        // front one, since focused windows are raised), from Hyprland's window positions.
        function windowAt(x: real, y: real): rect {
            const mx = monitor?.x ?? 0;
            const my = monitor?.y ?? 0;
            for (const t of Windows.recent) {
                const info = t.lastIpcObject;
                if (t.workspace !== monitor?.activeWorkspace || !info?.at || info.hidden)
                    continue;
                const r = Qt.rect(info.at[0] - mx, info.at[1] - my, info.size[0], info.size[1]);
                if (x >= r.x && x < r.x + r.width && y >= r.y && y < r.y + r.height)
                    return r;
            }
            return Qt.rect(0, 0, 0, 0);
        }

        // Cut the selection out of the frozen frame and save it. Done through a
        // ShaderEffectSource over the frozen picture, at the screen's real pixel size.
        function take(r: rect): void {
            if (r.width < 2 || r.height < 2)
                return;
            const scale = monitor?.scale ?? 1;
            cut.sourceRect = r;
            cut.width = r.width;
            cut.height = r.height;
            const path = root.fileName();
            cut.grabToImage(result => {
                result.saveToFile(path);
                capture.immediate = false;
                root.done(path);
            }, Qt.size(Math.round(r.width * scale), Math.round(r.height * scale)));
        }

        visible: root.open
        screen: Quickshell.screens.find(s => s.name === monitor?.name) ?? null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-screenshot"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            selection = Qt.rect(0, 0, 0, 0);
            if (visible) {
                frozen.captureFrame();
                keys.forceActiveFocus();
            }
        }

        // The frozen screen: one frame, captured when the overlay opens.
        ScreencopyView {
            id: frozen
            anchors.fill: parent
            captureSource: root.open ? capture.screen : null
            live: false
            onHasContentChanged: {
                if (hasContent && capture.immediate)
                    capture.take(Qt.rect(0, 0, width, height));
            }
        }

        // The cut-out that's saved. Behind the frozen picture, so it's never seen; not invisible,
        // or it wouldn't render for grabToImage.
        ShaderEffectSource {
            id: cut
            z: -1
            sourceItem: frozen
        }

        // Everything but the selection is dimmed: four rectangles around it. Only once the frame
        // is frozen, so the capture can't include the dimming.
        Item {
            anchors.fill: parent
            visible: frozen.hasContent && !capture.immediate

            readonly property rect hole: root.mode === "window" ? hover.windowRect : capture.selection
            readonly property color shade: Qt.rgba(0, 0, 0, 0.45)

            Rectangle { x: 0; y: 0; width: parent.width; height: parent.hole.y; color: parent.shade }
            Rectangle { x: 0; y: parent.hole.y + parent.hole.height; width: parent.width; height: parent.height - y; color: parent.shade }
            Rectangle { x: 0; y: parent.hole.y; width: parent.hole.x; height: parent.hole.height; color: parent.shade }
            Rectangle { x: parent.hole.x + parent.hole.width; y: parent.hole.y; width: parent.width - x; height: parent.hole.height; color: parent.shade }

            // The selection's outline, and its size.
            Rectangle {
                x: parent.hole.x
                y: parent.hole.y
                width: parent.hole.width
                height: parent.hole.height
                visible: width > 0
                color: "transparent"
                border.width: 2
                border.color: Colors.m3primary

                Rectangle {
                    anchors.top: parent.bottom
                    anchors.topMargin: Theme.spacing.s
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: sizeLabel.implicitWidth + Theme.spacing.m * 2
                    height: sizeLabel.implicitHeight + Theme.spacing.xs * 2
                    radius: Theme.radius.full
                    color: Colors.surfaceTranslucent

                    Text {
                        id: sizeLabel
                        anchors.centerIn: parent
                        text: Math.round(parent.parent.width * (capture.monitor?.scale ?? 1)) + " × "
                              + Math.round(parent.parent.height * (capture.monitor?.scale ?? 1))
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.small
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }

        // Region: drag. Window: hover and click. Screen: click.
        MouseArea {
            id: hover

            property point start
            property rect windowRect: Qt.rect(0, 0, 0, 0)

            anchors.fill: parent
            enabled: !capture.immediate
            hoverEnabled: true
            cursorShape: root.mode === "region" ? Qt.CrossCursor : Qt.PointingHandCursor

            onPositionChanged: mouse => {
                if (root.mode === "window") {
                    windowRect = capture.windowAt(mouse.x, mouse.y);
                } else if (root.mode === "region" && pressed) {
                    capture.selection = Qt.rect(Math.min(start.x, mouse.x), Math.min(start.y, mouse.y),
                                                Math.abs(mouse.x - start.x), Math.abs(mouse.y - start.y));
                }
            }
            onPressed: mouse => start = Qt.point(mouse.x, mouse.y)
            onReleased: {
                if (root.mode === "region")
                    capture.take(capture.selection);
            }
            onClicked: {
                if (root.mode === "window")
                    capture.take(windowRect);
                else if (root.mode === "screen")
                    capture.take(Qt.rect(0, 0, capture.width, capture.height));
            }
        }

        // Keyboard: Escape cancels; R / W / S switch modes.
        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: root.open = false
            Keys.onPressed: event => {
                if (event.key === Qt.Key_R)
                    root.mode = "region";
                else if (event.key === Qt.Key_W)
                    root.mode = "window";
                else if (event.key === Qt.Key_S)
                    root.mode = "screen";
            }
        }

        // The mode bar, at the top center (under the island).
        Rectangle {
            visible: frozen.hasContent && !capture.immediate
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.island.height + Theme.spacing.l
            width: bar.implicitWidth + Theme.spacing.s * 2
            height: bar.implicitHeight + Theme.spacing.s * 2
            radius: Theme.radius.full
            color: Colors.surfaceTranslucent

            Accessible.role: Accessible.ToolBar
            Accessible.name: "Screenshot"

            Row {
                id: bar
                anchors.centerIn: parent
                spacing: Theme.spacing.xs

                Repeater {
                    model: [
                        { mode: "region", icon: "crop", label: "Region" },
                        { mode: "window", icon: "select_window", label: "Window" },
                        { mode: "screen", icon: "fullscreen", label: "Screen" }
                    ]

                    MouseArea {
                        id: modeButton

                        required property var modelData
                        readonly property bool selected: root.mode === modelData.mode

                        width: modeRow.implicitWidth + Theme.spacing.l * 2
                        height: Theme.island.height
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.mode = modelData.mode

                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData.label
                        Accessible.checked: selected
                        Accessible.onPressAction: root.mode = modelData.mode

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius.full
                            color: modeButton.selected ? Colors.m3primaryContainer : Colors.m3onSurface
                            opacity: modeButton.selected ? 1 : modeButton.containsMouse ? 0.08 : 0
                        }

                        Row {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: Theme.spacing.s

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: modeButton.modelData.icon
                                color: modeButton.selected ? Colors.m3onPrimaryContainer : Colors.m3onSurface
                                font.pixelSize: Theme.icon.small
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modeButton.modelData.label
                                color: modeButton.selected ? Colors.m3onPrimaryContainer : Colors.m3onSurface
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.normal
                            }
                        }
                    }
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "close"
                    label: "Cancel"
                    iconSize: Theme.icon.small
                    onClicked: root.open = false
                }
            }
        }
    }
}
