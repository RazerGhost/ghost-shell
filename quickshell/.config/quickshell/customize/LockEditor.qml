import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.lock
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "../lock/LockClock.js" as LockClockJs
import "Presets.js" as Presets

// The lock screen editor, like long-pressing the iOS lock screen: the real lock screen, live,
// with Cancel and Done at the top and a sheet at the bottom with the looks (presets), the
// clock and the picture. Every change shows at once; Cancel puts the values from before back.
// The clock is outlined: clicking it opens the clock's tab. Opened from Settings -> Lock screen
// and the launcher (`qs ipc call customize lock`). The login screen follows (greeter/sync.sh).
Scope {
    id: root

    // The lock screen's settings as they were when the editor opened, for Cancel.
    property var saved: ({})
    property string tab: "looks"
    // The editor's own surfaces: no blur reaches them, so nearly solid.
    readonly property color solid: Qt.rgba(Colors.m3surfaceContainer.r, Colors.m3surfaceContainer.g, Colors.m3surfaceContainer.b, 0.94)

    function open(): void {
        if (editor.active)
            return;
        saved = Presets.snapshot(Settings.values, Presets.lockKeys);
        tab = "looks";
        Wallpaper.rescan();
        editor.active = true;
    }

    function done(): void {
        editor.active = false;
    }

    function cancel(): void {
        Presets.restore(Settings.values, saved);
        editor.active = false;
    }

    IpcHandler {
        target: "customize"

        function lock(): void {
            root.open();
        }

        // Closes an open editor, keeping its changes (like Done).
        function close(): void {
            root.done();
        }
    }

    LazyLoader {
        id: editor

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-customize"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Item {
                id: stage
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: root.cancel()
                Keys.onReturnPressed: root.done()
                Keys.onEnterPressed: root.done()

                // The lock screen itself, with input off: the editor's controls sit on top.
                LockContent {
                    id: lock
                    anchors.fill: parent
                    wallpaper: Wallpaper.lockPath
                    enabled: false

                    LockStatus {
                        width: parent.width
                    }
                }

                // The clock, outlined like an iOS lock screen widget being edited; click it for
                // the clock's options.
                Rectangle {
                    readonly property Item clock: lock.clockItem
                    readonly property Item column: clock?.parent ?? null

                    visible: (clock?.visible ?? false) || root.tab === "clock"
                    x: (column?.x ?? 0) + (clock?.x ?? 0) - Theme.spacing.m
                    y: (column?.y ?? 0) + (clock?.y ?? 0) - Theme.spacing.m
                    width: (clock?.width ?? 0) + Theme.spacing.m * 2
                    height: (clock?.height ?? 0) + Theme.spacing.m * 2
                    radius: Theme.radius.l
                    color: clockMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    border.width: Theme.outline.normal
                    border.color: root.tab === "clock" ? Colors.m3primary : Qt.rgba(1, 1, 1, 0.5)

                    Accessible.role: Accessible.Button
                    Accessible.name: "The clock's options"
                    Accessible.onPressAction: root.tab = "clock"

                    MouseArea {
                        id: clockMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = "clock"
                    }
                }

                // Cancel and Done in the top corners, nearly solid so they read over any picture
                // (Hyprland's blur can't reach under them: the lock screen is in this window).
                Surface {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: Theme.spacing.l * 2
                    width: cancelButton.width + Theme.spacing.xs * 2
                    height: cancelButton.height + Theme.spacing.xs * 2
                    radius: Theme.radius.full
                    color: root.solid

                    TextButton {
                        id: cancelButton
                        anchors.centerIn: parent
                        text: "Cancel"
                        onClicked: root.cancel()
                    }
                }

                Surface {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacing.l * 2
                    width: doneButton.width + Theme.spacing.xs * 2
                    height: doneButton.height + Theme.spacing.xs * 2
                    radius: Theme.radius.full
                    color: root.solid

                    TextButton {
                        id: doneButton
                        anchors.centerIn: parent
                        text: "Done"
                        filled: true
                        onClicked: root.done()
                    }
                }

                // The sheet: the looks, the clock and the picture.
                Surface {
                    id: sheet
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.spacing.l * 2
                    width: Math.min(parent.width - Theme.spacing.l * 4, Theme.editor.sheet)
                    height: sheetColumn.height + Theme.spacing.l
                    radius: Theme.radius.l * 1.5
                    color: root.solid
                    Behavior on height { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing } }

                    Column {
                        id: sheetColumn
                        width: parent.width
                        topPadding: Theme.spacing.l

                        Segmented {
                            anchors.horizontalCenter: parent.horizontalCenter
                            options: [
                                { value: "looks", label: "Looks" },
                                { value: "clock", label: "Clock" },
                                { value: "picture", label: "Picture" }
                            ]
                            current: root.tab
                            onPicked: v => root.tab = v
                        }

                        // Looks: your picture with each preset's clock on it.
                        ChoiceCards {
                            visible: root.tab === "looks"
                            options: Presets.lock.map(p => ({ value: p.name, label: p.name }))
                            current: Presets.current(Settings.values, Presets.lock)
                            onPicked: v => Presets.apply(Settings.values, Presets.lock, v)
                            art: Component {
                                Item {
                                    id: look
                                    readonly property var values: Presets.lock.find(p => p.name === parent.option.value).values

                                    Image {
                                        anchors.fill: parent
                                        source: Wallpaper.lockPath ? "file://" + Wallpaper.lockPath : ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: width * 2
                                        asynchronous: true
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "black"
                                        opacity: look.values.lockDim / 100 + 0.1
                                    }

                                    MiniClock {
                                        box: look
                                        style: look.values.lockClockStyle
                                        family: look.values.lockClockFont || Theme.font.sans
                                        fill: 0.5
                                        // Placed by its shrunk size, like the look's place on the screen.
                                        transformOrigin: Item.TopLeft
                                        x: look.values.lockLayout === "left" ? look.width * 0.08 : (look.width - width * scale) / 2
                                        y: look.values.lockLayout === "top" ? look.height * 0.12
                                           : look.values.lockLayout === "center" ? (look.height - height * scale) / 2 : look.height * 0.88 - height * scale
                                    }
                                }
                            }
                        }

                        // Clock: style and font by sight; place and size as segments; the time
                        // and date on or off.
                        Column {
                            width: parent.width
                            visible: root.tab === "clock"

                            ChoiceCards {
                                title: "Style"
                                options: LockClockJs.styles.map(v => ({ value: v, label: ({ big: "Big", stacked: "Stacked", thin: "Thin", analog: "Analog" })[v] }))
                                current: LockClockJs.pick(Settings.values.lockClockStyle, LockClockJs.styles)
                                onPicked: v => Settings.values.lockClockStyle = v
                                art: Component {
                                    Rectangle {
                                        color: Colors.m3surfaceContainerHighest

                                        MiniClock {
                                            anchors.centerIn: parent
                                            box: parent
                                            style: parent.parent.option.value
                                        }
                                    }
                                }
                            }

                            ChoiceCards {
                                title: "Font"
                                scrolls: true
                                options: ["", "Inter Display", "Noto Serif", "C059", "Nimbus Sans Narrow", "MesloLGS Nerd Font"]
                                    .filter(f => f === "" || Qt.fontFamilies().includes(f))
                                    .map(f => ({ value: f, label: f === "" ? "Same as text" : f === "MesloLGS Nerd Font" ? "Monospaced" : f }))
                                current: Settings.values.lockClockFont
                                onPicked: v => Settings.values.lockClockFont = v
                                art: Component {
                                    Rectangle {
                                        color: Colors.m3surfaceContainerHighest

                                        Text {
                                            anchors.centerIn: parent
                                            text: "10:09"
                                            color: Colors.m3onSurface
                                            font.family: parent.parent.option.value || Theme.font.sans
                                            font.pixelSize: parent.height * 0.42
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                            }

                            SettingRow {
                                title: "Place"

                                Segmented {
                                    options: LockClockJs.layouts.map(v => ({ value: v, label: ({ top: "Top", center: "Middle", left: "Bottom left" })[v] }))
                                    current: LockClockJs.pick(Settings.values.lockLayout, LockClockJs.layouts)
                                    onPicked: v => Settings.values.lockLayout = v
                                }
                            }

                            SettingRow {
                                title: "Size"

                                Segmented {
                                    options: LockClockJs.sizes.map(v => ({ value: v, label: v + " %" }))
                                    current: LockClockJs.pick(Settings.values.lockClockSize, LockClockJs.sizes)
                                    onPicked: v => Settings.values.lockClockSize = v
                                }
                            }

                            SettingRow {
                                title: "Show"

                                Row {
                                    spacing: Theme.spacing.m

                                    Repeater {
                                        model: [{ key: "lockClock", label: "Time" }, { key: "lockDate", label: "Date" }]

                                        Row {
                                            id: shown
                                            required property var modelData
                                            spacing: Theme.spacing.s

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: shown.modelData.label
                                                color: Colors.m3onSurface
                                                font.family: Theme.font.sans
                                                font.pixelSize: Theme.font.normal
                                            }

                                            Switch {
                                                anchors.verticalCenter: parent.verticalCenter
                                                label: "Show the " + shown.modelData.label.toLowerCase()
                                                checked: Settings.values[shown.modelData.key]
                                                onToggled: Settings.values[shown.modelData.key] = !checked
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Picture: the desktop's or one of yours, then blur and darkening.
                        Column {
                            width: parent.width
                            visible: root.tab === "picture"

                            ChoiceCards {
                                scrolls: true
                                // Pictures only: the lock and login screens can't play a video.
                                options: [{ value: "", label: "Desktop's" }].concat(
                                    Wallpaper.pictures.filter(p => !p.video).map(p => ({ value: p.filePath, label: p.fileName })))
                                current: Settings.values.lockWallpaper
                                onPicked: v => Settings.values.lockWallpaper = v
                                art: Component {
                                    Image {
                                        readonly property string file: parent.option.value || Wallpaper.path
                                        source: file ? "file://" + file : ""
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: width * 2
                                        asynchronous: true
                                    }
                                }
                            }

                            SettingRow {
                                title: "Blur"

                                Stepper {
                                    label: "Blur"
                                    values: Array.from({ length: 11 }, (_, i) => i * 10)
                                    value: Settings.values.lockBlur
                                    format: v => v === 0 ? "Off" : v + " %"
                                    onPicked: v => Settings.values.lockBlur = v
                                }
                            }

                            SettingRow {
                                title: "Darken"

                                Stepper {
                                    label: "Darken"
                                    values: Array.from({ length: 13 }, (_, i) => i * 5) // up to 60 %
                                    value: Settings.values.lockDim
                                    format: v => v === 0 ? "Off" : v + " %"
                                    onPicked: v => Settings.values.lockDim = v
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
