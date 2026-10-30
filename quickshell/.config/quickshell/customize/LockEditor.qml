import QtQuick
import Quickshell
import Quickshell.Hyprland
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
// as a card on the background color, with Cancel and Done at the top and a sheet at the bottom with the looks (presets), the
// clock and the picture. Every change shows at once; Cancel puts the values from before back.
// The clock is outlined: clicking it opens the clock's tab. Opened from Settings -> Lock screen
// and the launcher (Customize.qml). The login screen follows (greeter/sync.sh).
Scope {
    id: root

    // The lock screen's settings as they were when the editor opened, for Cancel.
    property var saved: ({})

    function open(): void {
        if (editor.active)
            return;
        saved = Presets.snapshot(Settings.values, Presets.lockKeys);
        Wallpaper.rescan();
        editor.active = true;
    }

    function done(): void {
        editor.active = false;
    }

    function close(): void {
        if (editor.active)
            root.done();
    }

    function cancel(): void {
        Presets.restore(Settings.values, saved);
        editor.active = false;
    }

    LazyLoader {
        id: editor

        PanelWindow {
            id: window

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Colors.m3surface
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-customize"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // The lock screen as a card, like GNOME's workspaces and Android's widget editing:
            // laid out at the screen's size and scaled to fit between the top buttons and the
            // sheet, on the background color. It follows the sheet's height as tabs change.
            readonly property real top: Theme.spacing.l * 2
            readonly property real bottom: chrome.sheet.y - Theme.spacing.l * 1.5
            readonly property real cardScale: Math.min((width - Theme.spacing.l * 4) / width,
                                                       Math.max(bottom - top, 1) / height)

            ClippingRectangle {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                y: window.top + (window.bottom - window.top - height) / 2
                width: window.width * window.cardScale
                height: window.height * window.cardScale
                radius: Theme.radius.l * 1.5
                color: "black"

                Item {
                    width: window.width
                    height: window.height
                    scale: window.cardScale
                    transformOrigin: Item.TopLeft

                    // The lock screen itself, with input off.
                    LockContent {
                        id: lock
                        anchors.fill: parent
                        wallpaper: Wallpaper.lockPath
                        enabled: false

                        LockStatus {
                            width: parent.width
                        }
                    }

                    // The clock, outlined like an iOS lock screen widget being edited; click it
                    // for the clock's options. Its line is scaled back to the usual width.
                    Rectangle {
                        readonly property Item clock: lock.clockItem
                        readonly property Item column: clock?.parent ?? null

                        visible: (clock?.visible ?? false) || chrome.tab === "clock"
                        x: (column?.x ?? 0) + (clock?.x ?? 0) - Theme.spacing.m
                        y: (column?.y ?? 0) + (clock?.y ?? 0) - Theme.spacing.m
                        width: (clock?.width ?? 0) + Theme.spacing.m * 2
                        height: (clock?.height ?? 0) + Theme.spacing.m * 2
                        radius: Theme.radius.l
                        color: clockMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        border.width: Theme.outline.normal / window.cardScale
                        border.color: chrome.tab === "clock" ? Colors.m3primary : Qt.rgba(1, 1, 1, 0.5)

                        Accessible.role: Accessible.Button
                        Accessible.name: "The clock's options"
                        Accessible.onPressAction: chrome.tab = "clock"

                        MouseArea {
                            id: clockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: chrome.tab = "clock"
                        }
                    }
                }
            }

            EditorChrome {
                id: chrome
                tabs: [
                    { value: "looks", label: "Looks" },
                    { value: "clock", label: "Clock" },
                    { value: "picture", label: "Picture" }
                ]
                onCancelled: root.cancel()
                onFinished: root.done()

                // Looks: your picture with each preset's clock on it, and first your own look
                // while it matches none of them ("" is yours).
                ChoiceCards {
                    visible: chrome.tab === "looks"
                    options: (Presets.current(Settings.values, Presets.lock) === "" ? [{ value: "", label: "Yours" }] : [])
                        .concat(Presets.lock.map(p => ({ value: p.name, label: p.name })))
                    current: Presets.current(Settings.values, Presets.lock)
                    onPicked: v => {
                        if (v !== "")
                            Presets.apply(Settings.values, Presets.lock, v);
                    }
                    art: Component {
                        Item {
                            id: look
                            readonly property var values: parent.option.value === "" ? Settings.values
                                : Presets.lock.find(p => p.name === parent.option.value).values

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

                // Clock: style and font by sight side by side; place, size and the time and
                // date in a row under them.
                Column {
                    width: parent.width
                    visible: chrome.tab === "clock"

                    Row {
                        width: parent.width

                        // The same card size as the fonts beside it, so the two rows line up.
                        ChoiceCards {
                            width: parent.width / 2
                            cardWidth: fontCards.cardWidth
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
                            id: fontCards
                            width: parent.width / 2
                            title: "Font"
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
                                        font.pixelSize: parent.height * 0.36
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width

                        SettingRow {
                            width: parent.width / 3
                            title: "Place"

                            Segmented {
                                options: LockClockJs.layouts.map(v => ({ value: v, label: ({ top: "Top", center: "Middle", left: "Bottom left" })[v] }))
                                current: LockClockJs.pick(Settings.values.lockLayout, LockClockJs.layouts)
                                onPicked: v => Settings.values.lockLayout = v
                            }
                        }

                        SettingRow {
                            width: parent.width / 3
                            title: "Size"

                            Segmented {
                                options: LockClockJs.sizes.map(v => ({ value: v, label: v + " %" }))
                                current: LockClockJs.pick(Settings.values.lockClockSize, LockClockJs.sizes)
                                onPicked: v => Settings.values.lockClockSize = v
                            }
                        }

                        SettingRow {
                            width: parent.width / 3
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
                }

                // Picture: the desktop's or one of yours, then blur and darkening.
                Column {
                    width: parent.width
                    visible: chrome.tab === "picture"

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

                    // Blur and darkening side by side.
                    Row {
                        width: parent.width

                        Column {
                            width: parent.width / 2

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
                        }

                        Column {
                            width: parent.width / 2

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
