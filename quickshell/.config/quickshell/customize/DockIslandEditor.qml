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
// the dock's own right-click menu. Cancel writes the earlier settings back. Opened from
// Settings -> Windows and the launcher (Customize.qml).
Scope {
    id: root

    property var saved: ({})

    function open(): void {
        if (editor.active)
            return;
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

    function cancel(): void {
        Presets.restore(Settings.values, saved);
        close();
    }

    LazyLoader {
        id: editor

        PanelWindow {
            id: window

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-customize"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Input only on the editor's own controls: the dock underneath keeps its clicks
            // (right-click an app to pin or move it).
            mask: Region {
                item: chrome.sheet
            }

            BackgroundEffect.blurRegion: Region {
                item: chrome.sheet
                radius: chrome.sheet.radius
            }

            EditorChrome {
                id: chrome
                tabs: [{ value: "island", label: "Island" }, { value: "dock", label: "Dock" }]
                glass: true
                centered: true
                onCancelled: root.cancel()
                onFinished: root.close()

                // Island: dots, clock, status icons.
                SheetGrid {
                    visible: chrome.tab === "island"

                    // Seven choices: two cells.
                    SettingRow {
                        span: 2
                        title: "Workspace dots"
                        subtitle: Settings.values.workspaceDots === 0 ? "Only the ones in use; scrolling steps between them" : "Always this many, more when in use"

                        Segmented {
                            options: ThemeScale.workspaceDots.map(v => ({ value: v, label: v === 0 ? "In use" : String(v) }))
                            current: ThemeScale.pick(Settings.values.workspaceDots, ThemeScale.workspaceDots, 5)
                            onPicked: v => Settings.values.workspaceDots = v
                        }
                    }

                    Repeater {
                        model: [
                            { key: "clockDate", title: "The day next to the time", subtitle: "Thu 29  14:32" },
                            { key: "clockSeconds", title: "Seconds", subtitle: "" },
                            { key: "islandMedia", title: "Music takes the clock's place", subtitle: "Its cover while it plays; hover it for the time" }
                        ]

                        SettingRow {
                            id: clockRow
                            required property var modelData
                            title: modelData.title
                            subtitle: modelData.subtitle

                            Switch {
                                label: clockRow.modelData.title
                                checked: Settings.values[clockRow.modelData.key]
                                onToggled: Settings.values[clockRow.modelData.key] = !checked
                            }
                        }
                    }

                    // Status icons as chips, filled while shown (the privacy ones always show:
                    // recording, microphone, camera, screen sharing).
                    Column {
                        width: parent.width
                        leftPadding: Theme.spacing.l
                        rightPadding: Theme.spacing.l
                        topPadding: Theme.spacing.s
                        bottomPadding: Theme.spacing.m
                        spacing: Theme.spacing.s

                        Text {
                            text: "Status icons"
                            color: Colors.m3onSurface
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.normal
                            font.weight: Font.Medium
                        }

                        Flow {
                            width: parent.width - parent.leftPadding - parent.rightPadding
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
                                    border.width: shown ? 0 : 1
                                    border.color: Colors.m3outlineVariant

                                    Accessible.role: Accessible.CheckBox
                                    Accessible.name: modelData.label
                                    Accessible.checked: shown
                                    Accessible.onToggleAction: toggle()
                                    activeFocusOnTab: true
                                    Keys.onReturnPressed: toggle()
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

                // Dock: when it shows, its icons' size.
                SheetGrid {
                    visible: chrome.tab === "dock"

                    SettingRow {
                        title: "Show the dock"
                        subtitle: ({ hide: "When the pointer touches the bottom edge", always: "All the time; windows tile above it",
                                     off: "Never" })[Settings.values.dockMode] ?? ""

                        Segmented {
                            options: [{ value: "hide", label: "At the edge" }, { value: "always", label: "Always" }, { value: "off", label: "Off" }]
                            current: Settings.values.dockMode
                            onPicked: v => Settings.values.dockMode = v
                        }
                    }

                    SettingRow {
                        title: "Icon size"

                        Segmented {
                            options: ThemeScale.dockIcons.map(v => ({ value: v, label: ({ 36: "Small", 44: "Normal", 52: "Large", 60: "Larger" })[v] }))
                            current: ThemeScale.pick(Settings.values.dockIconSize, ThemeScale.dockIcons, 44)
                            onPicked: v => Settings.values.dockIconSize = v
                        }
                    }

                    Text {
                        width: parent.cellWidth
                        leftPadding: Theme.spacing.l
                        rightPadding: Theme.spacing.l
                        topPadding: Theme.spacing.m
                        bottomPadding: Theme.spacing.m
                        text: "Right-click an app in the dock to pin it, unpin it or move it left or right."
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
