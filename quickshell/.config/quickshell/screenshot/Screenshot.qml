import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import "../services/CaptureFolders.js" as CaptureFolders

// Screenshots, like Windows' Snipping Tool (user's choice). Super+Shift+S freezes the focused
// monitor and dims it; a bar at the top picks what to do (a screenshot, the text in it (OCR), a
// QR code in it, or a recording) and where: Region (drag a rectangle), Window (click one) or
// Screen (click anywhere); and has the color picker. Escape cancels. Print Screen takes the whole
// screen at once; Super+Shift+R starts (or stops) a recording.
// Every screenshot is saved to ~/Pictures/Screenshots (or Settings' folder), copied to the clipboard, and announced
// with a notification showing it (click it to open the picture). Text and QR codes are copied
// (the picture they came from isn't kept); recordings are services/Recorder.qml's.
//
// The frozen picture is one frame from ScreencopyView, and the screenshot is cut from that same
// frame, so it shows exactly what was frozen (an open menu or tooltip included).
Scope {
    id: root

    property bool open: false
    property string mode: "region" // "region", "window" or "screen"
    property string action: "shot" // "shot", "text", "qr" or "record"
    // Settings -> Screenshots and recordings (CaptureFolders.js, tested).
    readonly property string folder: CaptureFolders.folder(Settings.values.screenshotFolder, Quickshell.env("HOME"),
                                                           Quickshell.env("HOME") + "/Pictures/Screenshots")

    function start(withMode: string, withAction: string): void {
        mode = withMode;
        action = withAction;
        Hyprland.refreshToplevels(); // fresh window positions for Window mode
        open = true;
    }

    // The follow-ups (copying, notifying, reading text or a QR code, the color picker) are shell
    // in screenshot/capture.sh, run detached.
    function follow(args: var): void {
        Quickshell.execDetached(["sh", Quickshell.shellDir + "/screenshot/capture.sh", ...args]);
    }

    // Saves the picture and tells the user; `path` is where grabToImage wrote it. The
    // notification can open it, or draw on it in satty (the capture module).
    function done(path: string): void {
        open = false;
        Sounds.play("feedback", "screen-capture");
        follow(["save", path, CaptureFolders.short(folder, Quickshell.env("HOME"))]);
    }

    function fileName(): string {
        return folder + "/Screenshot_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png";
    }

    // The text in a picture, or the QR code in it, copied and shown in a notification. The
    // picture was only for reading, so the script removes it.
    function read(path: string): void {
        open = false;
        follow([action === "text" ? "text" : "qr", path]);
    }

    // The color picker (hyprpicker), copied as #rrggbb.
    function pickColor(): void {
        open = false;
        follow(["color"]);
    }

    IpcHandler {
        target: "screenshot"

        // Super+Shift+S: the overlay, starting in Region mode.
        function region(): void {
            root.start("region", "shot");
        }

        // Super+Shift+R: stops a recording, or opens the overlay to start one.
        function record(): void {
            if (Recorder.recording)
                Recorder.stop();
            else
                root.start("region", "record");
        }

        // Print Screen: the whole focused monitor, without the overlay.
        function screen(): void {
            root.start("screen", "shot");
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
        function take(selection: rect): void {
            // Whole pixels: the pointer reports fractional positions, and a crop starting between
            // two pixels blends every pixel with its neighbour (blurry text). On whole pixels the
            // result is identical to grim's.
            const x = Math.round(selection.x);
            const y = Math.round(selection.y);
            const r = Qt.rect(x, y, Math.round(selection.x + selection.width) - x,
                              Math.round(selection.y + selection.height) - y);
            if (r.width < 2 || r.height < 2)
                return;
            const scale = monitor?.scale ?? 1;
            if (root.action === "record") {
                // Recorded live, not from the frozen frame: hand the area over to the recorder,
                // in the monitor's pixels and global coordinates.
                root.open = false;
                if (root.mode === "screen")
                    Recorder.start(monitor.name, null);
                else
                    Recorder.start("region", { x: (monitor.x + r.x) * scale, y: (monitor.y + r.y) * scale,
                                               width: r.width * scale, height: r.height * scale });
                return;
            }
            cut.sourceRect = r;
            cut.width = r.width;
            cut.height = r.height;
            // Text and QR codes are read from a temporary picture, not kept in Pictures.
            const path = root.action === "shot" ? root.fileName()
                : Quickshell.env("XDG_RUNTIME_DIR") + "/qs-capture-" + Date.now() + ".png";
            cut.grabToImage(result => {
                result.saveToFile(path);
                capture.immediate = false;
                if (root.action === "shot")
                    root.done(path);
                else
                    root.read(path);
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
            readonly property color shade: Colors.scrim

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

                Surface {
                    anchors.top: parent.bottom
                    anchors.topMargin: Theme.spacing.s
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: sizeLabel.implicitWidth + Theme.spacing.m * 2
                    height: sizeLabel.implicitHeight + Theme.spacing.xs * 2
                    radius: Theme.radius.full

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

        // Keyboard: Escape cancels; R / W / S pick where; P / T / Q / V what (picture, text, QR
        // code, video); C the color picker.
        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: root.open = false
            Keys.onPressed: event => {
                const modes = { [Qt.Key_R]: "region", [Qt.Key_W]: "window", [Qt.Key_S]: "screen" };
                const actions = { [Qt.Key_P]: "shot", [Qt.Key_T]: "text", [Qt.Key_Q]: "qr", [Qt.Key_V]: "record" };
                if (modes[event.key])
                    root.mode = modes[event.key];
                else if (actions[event.key])
                    root.action = actions[event.key];
                else if (event.key === Qt.Key_C)
                    root.pickColor();
            }
        }

        // The mode bar, at the top center (under the island).
        Surface {
            visible: frozen.hasContent && !capture.immediate
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.island.height + Theme.spacing.l
            width: bar.implicitWidth + Theme.spacing.s * 2
            height: bar.implicitHeight + Theme.spacing.s * 2
            radius: Theme.radius.full

            Accessible.role: Accessible.ToolBar
            Accessible.name: "Screenshot"

            Row {
                id: bar
                anchors.centerIn: parent
                spacing: Theme.spacing.xs

                // What to do.
                Repeater {
                    model: [
                        { value: "shot", icon: "photo_camera", label: "Screenshot" },
                        { value: "text", icon: "text_fields", label: "Text" },
                        { value: "qr", icon: "qr_code_scanner", label: "QR code" },
                        { value: "record", icon: "videocam", label: "Record" }
                    ]

                    CaptureChoice {
                        required property var modelData
                        icon: modelData.icon
                        label: modelData.label
                        selected: root.action === modelData.value
                        onPicked: root.action = modelData.value
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: Theme.island.height * 0.6
                    color: Colors.m3outlineVariant
                }

                // Where.
                Repeater {
                    model: [
                        { value: "region", icon: "crop", label: "Region" },
                        { value: "window", icon: "select_window", label: "Window" },
                        { value: "screen", icon: "fullscreen", label: "Screen" }
                    ]

                    CaptureChoice {
                        required property var modelData
                        icon: modelData.icon
                        label: modelData.label
                        selected: root.mode === modelData.value
                        onPicked: root.mode = modelData.value
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: Theme.island.height * 0.6
                    color: Colors.m3outlineVariant
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "colorize"
                    label: "Color picker"
                    iconSize: Theme.icon.small
                    onClicked: root.pickColor()
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
