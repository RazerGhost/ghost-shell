import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "../theme/ThemeScale.js" as ThemeScale
import "Presets.js" as Presets

// The dock and island editor, like editing macOS's menu bar and Dock in place: the real island
// and dock (shown while it's open, wherever the dock would hide) change as you pick, on an
// empty workspace (Done or Cancel go back). The sheet sits in the middle of the screen, clear
// of both. Island: the workspace dots, the clock and
// which status icons show. Dock: when it shows and its icons' size; pinning and moving apps is
// done on the dock itself (drag, right-click). Cancel writes the earlier settings back. Opened from
// Settings -> Windows and the launcher (Customize.qml).
Scope {
    id: root

    property var saved: ({})
    // The screen it opened on, kept while it's open (the focused one could change under it).
    property string screenName: ""

    function open(): void {
        if (editor.active)
            return;
        screenName = Hyprland.focusedMonitor?.name ?? "";
        saved = Presets.snapshot(Settings.values, Presets.dockIslandKeys);
        // An empty workspace (user's choice): the sheet reads clearly over the wallpaper.
        Editing.toEmptyWorkspace();
        Editing.dock = true;
        editor.active = true;
    }

    function close(): void {
        if (!editor.active)
            return;
        editor.active = false;
        Editing.dock = false;
        Editing.back();
    }

    // Closed first: its Looks gallery would save the restored settings into a look of yours.
    function cancel(): void {
        close();
        Presets.restore(Settings.values, saved);
    }

    LazyLoader {
        id: editor

        PanelWindow {
            id: window

            screen: Quickshell.screens.find(s => s.name === root.screenName) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-customize"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Input only on the editor's own controls: the dock underneath keeps its clicks
            // (drag an app to move or unpin it, right-click to pin it).
            mask: Region {
                item: chrome.sheet
            }

            BackgroundEffect.blurRegion: Region {
                item: chrome.sheet
                radius: chrome.sheet.radius
            }

            EditorChrome {
                id: chrome
                tabs: [{ value: "looks", label: "Looks" }, { value: "island", label: "Island" }, { value: "dock", label: "Dock" }]
                glass: true
                centered: true
                onCancelled: root.cancel()
                onFinished: root.close()

                // Looks: the island and dock in each look, small on your wallpaper: the dots, the
                // clock as it would read, and the dock (faint when it waits at the edge).
                SheetTiles {
                    visible: chrome.tab === "looks"

                    LooksTile {
                        live: editor.active
                        picture: Wallpaper.stillPath
                        savedKey: "dockLooks"
                        savedKeys: Presets.dockIslandKeys.filter(k => k !== "dockLooks")
                        subtitle: "How much the island shows, and the dock"
                        presets: Presets.dockIsland
                        fadeColor: Qt.tint(Colors.surfaceTranslucent, Colors.tint)
                        art: Component {
                            Item {
                                id: look
                                readonly property var values: parent.option.values
                                readonly property real unit: width / 40


                                // The island at the top edge.
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: islandRow.width + look.unit * 3
                                    height: look.unit * 3.2
                                    radius: height / 2
                                    color: Colors.m3surfaceContainer

                                    Row {
                                        id: islandRow
                                        anchors.centerIn: parent
                                        spacing: look.unit

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: look.unit * 0.4

                                            Repeater {
                                                model: look.values.workspaceDots || 2

                                                Rectangle {
                                                    width: look.unit * 0.8
                                                    height: width
                                                    radius: width / 2
                                                    color: index === 0 ? Colors.m3primary : Colors.m3onSurfaceVariant
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            // A sample afternoon, as your clock would read it (12 or 24 hours).
                                            text: (look.values.clockDate ? "Fri 30  " : "")
                                                  + Qt.formatTime(new Date(2026, 0, 30, 14, 32, 5),
                                                                  (Settings.values.clock24Hour ? "HH:mm" : "h:mm") + (look.values.clockSeconds ? ":ss" : "")
                                                                  + (Settings.values.clock24Hour ? "" : " AP"))
                                            color: Colors.m3onSurface
                                            font.family: Theme.font.sans
                                            font.pixelSize: look.unit * 1.6
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                // The dock at the bottom, its icons at the look's size.
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: look.unit
                                    width: dockRow.width + look.unit * 2
                                    height: dockRow.height + look.unit * 1.2
                                    radius: look.unit * 1.6
                                    color: Colors.m3surfaceContainer
                                    opacity: look.values.dockMode === "always" ? 1 : 0.35

                                    Row {
                                        id: dockRow
                                        anchors.centerIn: parent
                                        spacing: look.unit * 0.5

                                        Repeater {
                                            model: 5

                                            Rectangle {
                                                width: look.unit * 2.6 * look.values.dockIconSize / 44
                                                height: width
                                                radius: width * 0.3
                                                color: index === 0 ? Colors.m3primary : Colors.m3onSurfaceVariant
                                                opacity: 0.85
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Island: the workspace dots (drawn at your count), the clock (as it will read) and
                // which status icons show.
                SheetTiles {
                    visible: chrome.tab === "island"

                    SheetTile {
                        title: "Workspace dots"
                        subtitle: Settings.values.workspaceDots === 0 ? "Only the ones in use" : "Always this many, more when in use"
                        weight: 1.3

                        // The dots as the island draws them: the current one a wide pill.
                        Row {
                            readonly property int count: ThemeScale.pick(Settings.values.workspaceDots, ThemeScale.workspaceDots, 5) || 3
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: Theme.spacing.m
                            spacing: Theme.spacing.s

                            Repeater {
                                model: parent.count

                                Rectangle {
                                    required property int index
                                    width: index === 1 ? Theme.spacing.l * 2 : Theme.spacing.m
                                    height: Theme.spacing.m
                                    radius: height / 2
                                    color: index === 1 ? Colors.m3primary : Colors.m3onSurfaceVariant
                                    opacity: index === 1 || Settings.values.workspaceDots === 0 ? 1 : Theme.state.disabled
                                    Behavior on width { NumberAnimation { duration: Theme.anim.fast } }
                                }
                            }
                        }


                        Segmented {
                            id: dotsChoice
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            options: ThemeScale.workspaceDots.map(v => ({ value: v, label: v === 0 ? "In use" : String(v) }))
                            current: ThemeScale.pick(Settings.values.workspaceDots, ThemeScale.workspaceDots, 5)
                            onPicked: v => Settings.values.workspaceDots = v
                        }
                    }

                    SheetTile {
                        title: "Clock"
                        subtitle: "In the island's middle"

                        Column {
                            anchors.fill: parent
                            spacing: Theme.spacing.s

                            // The clock as it will read.
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                // A fixed sample time in your clock's format.
                                text: (Settings.values.clockDate ? "Thu 29  " : "")
                                      + Qt.formatTime(new Date(2026, 0, 1, 14, 32, 5),
                                                      (Settings.values.clock24Hour ? "HH:mm" : "h:mm") + (Settings.values.clockSeconds ? ":ss" : "")
                                                      + (Settings.values.clock24Hour ? "" : " AP"))
                                color: Colors.m3onSurface
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.large
                                font.weight: Font.DemiBold
                                font.features: { "tnum": 1 }
                            }

                            Repeater {
                                model: [
                                    { key: "clockDate", label: "The day too" },
                                    { key: "clockSeconds", label: "Seconds" },
                                    { key: "islandMedia", label: "Music's cover instead" }
                                ]

                                TileRow {
                                    id: clockRow
                                    required property var modelData
                                    label: modelData.label

                                    Switch {
                                        label: clockRow.modelData.label
                                        checked: Settings.values[clockRow.modelData.key]
                                        onToggled: Settings.values[clockRow.modelData.key] = !checked
                                    }
                                }
                            }
                        }
                    }

                    // Status icons as chips, filled while shown (the privacy ones always show:
                    // recording, microphone, camera, screen sharing).
                    SheetTile {
                        title: "Status icons"
                        subtitle: "Microphone, camera and sharing always show"
                        weight: 1.4

                        Flow {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: Theme.spacing.s


                                Repeater {
                                    model: [
                                        { key: "wifi", icon: "wifi", label: "Wi-Fi" },
                                        { key: "bluetooth", icon: "bluetooth", label: "Bluetooth" },
                                        { key: "vpn", icon: "vpn_key", label: "VPN" },
                                        { key: "airplane", icon: "flight", label: "Airplane" },
                                        { key: "timer", icon: "timer", label: "Timer" },
                                        { key: "updates", icon: "download", label: "Updates" },
                                        { key: "muted", icon: "volume_off", label: "Muted" },
                                        { key: "battery", icon: "battery_full", label: "Battery" }
                                    ]

                                    Rectangle {
                                        id: chip

                                        required property var modelData
                                        readonly property var hidden: Array.from(Settings.values.hiddenStatusIcons ?? [])
                                        readonly property bool shown: !hidden.includes(modelData.key)

                                        function toggle(): void {
                                            Settings.values.hiddenStatusIcons = shown ? [...hidden, modelData.key]
                                                                                      : hidden.filter(k => k !== modelData.key);
                                        }

                                        width: chipRow.width + Theme.spacing.m * 2
                                        height: Theme.island.height
                                        radius: Theme.radius.full
                                        color: shown ? Colors.m3primaryContainer : "transparent"
                                        border.width: shown ? 0 : Theme.outline.normal
                                        border.color: Colors.m3outlineVariant

                                        Accessible.role: Accessible.CheckBox
                                        Accessible.name: modelData.label
                                        Accessible.checked: shown
                                        Accessible.onToggleAction: toggle()
                                        activeFocusOnTab: true
                                        Keys.onReturnPressed: toggle()
                                        Keys.onEnterPressed: toggle()
                                        Keys.onSpacePressed: toggle()

                                        Row {
                                            id: chipRow
                                            anchors.centerIn: parent
                                            spacing: Theme.spacing.xs

                                            MaterialIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                icon: chip.modelData.icon
                                                color: chip.shown ? Colors.m3onPrimaryContainer : Colors.m3onSurfaceVariant
                                                font.pixelSize: Theme.icon.small
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: chip.modelData.label
                                                color: chip.shown ? Colors.m3onPrimaryContainer : Colors.m3onSurfaceVariant
                                                font.family: Theme.font.sans
                                                font.pixelSize: Theme.font.small
                                            }
                                        }

                                        StateLayer {
                                            radius: chip.radius
                                            color: Colors.m3onSurface
                                            hovered: chipMouse.containsMouse
                                        }

                                        FocusRing {
                                            radius: chip.radius
                                        }

                                        MouseArea {
                                            id: chipMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: chip.toggle()
                                        }
                                    }
                                }
                        }
                    }
                }

                // Dock: when it shows, its icons' size (drawn at it), and where pinning is.
                SheetTiles {
                    visible: chrome.tab === "dock"

                    SheetTile {
                        title: "Show the dock"
                        subtitle: ({ hide: "When the pointer touches the bottom edge", always: "All the time; windows tile above it",
                                     off: "Never" })[Settings.values.dockMode] ?? ""

                        Segmented {
                            anchors.centerIn: parent
                            options: [{ value: "hide", label: "At the edge" }, { value: "always", label: "Always" }, { value: "off", label: "Off" }]
                            current: Settings.values.dockMode
                            onPicked: v => Settings.values.dockMode = v
                        }
                    }

                    SheetTile {
                        title: "Icon size"
                        weight: 1.3

                        // Four icons at the chosen size, like the dock's.
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: sizeChoice.top
                            anchors.bottomMargin: Theme.spacing.m
                            spacing: Theme.spacing.s

                            Repeater {
                                model: [Colors.m3primaryContainer, Colors.m3surfaceContainerHighest, Colors.m3primary, Colors.m3surfaceContainerHighest]

                                Rectangle {
                                    required property color modelData
                                    anchors.bottom: parent.bottom
                                    width: Theme.dock.icon
                                    height: width
                                    radius: width * 0.28
                                    color: modelData
                                    Behavior on width { NumberAnimation { duration: Theme.anim.fast } }
                                }
                            }
                        }

                        Segmented {
                            id: sizeChoice
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            options: ThemeScale.dockIcons.map(v => ({ value: v, label: ({ 36: "Small", 44: "Normal", 52: "Large", 60: "Larger" })[v] }))
                            current: ThemeScale.pick(Settings.values.dockIconSize, ThemeScale.dockIcons, 44)
                            onPicked: v => Settings.values.dockIconSize = v
                        }
                    }

                    SheetTile {
                        title: "Pinned apps"
                        weight: 0.8

                        Column {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: Theme.spacing.s

                            MaterialIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: "push_pin"
                                color: Colors.m3onSurfaceVariant
                                font.pixelSize: Theme.font.title * 1.4
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: "Drag an app along the dock to move it, or up off it to unpin it; right-click to pin"
                                color: Colors.m3onSurfaceVariant
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.small
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}
