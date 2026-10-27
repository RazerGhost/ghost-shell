import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.controlcenter
import qs.theme

// The bar: an "island" attached to the top edge of each monitor with the workspaces, the
// time and status icons. Clicking the time or the status icons morphs it into a menu:
// "today" (calendar, media) or "settings" (quick settings). One menu is open at a time,
// on one monitor; click outside it or press Escape to close it.
Scope {
    id: root

    property string panel: ""      // "", "today" or "settings"
    property string screenName: "" // the monitor the menu is open on

    function toggle(name: string, screen: string): void {
        if (panel === name && screenName === screen) {
            panel = "";
        } else {
            panel = name;
            screenName = screen;
        }
    }

    // From Hyprland binds: qs ipc call island toggle settings (or: today)
    IpcHandler {
        target: "island"

        function toggle(panel: string): void {
            root.toggle(panel, Hyprland.focusedMonitor?.name ?? "");
        }

        function close(): void {
            root.panel = "";
        }
    }

    // One island per monitor: Variants creates a delegate for each entry in the model
    // and destroys it when the monitor goes away.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData
            screen: modelData

            readonly property string panel: root.screenName === modelData.name ? root.panel : ""
            readonly property bool open: panel !== ""
            readonly property real closedWidth: topRow.implicitWidth + Theme.island.padding * 2

            // The window is as big as the island can get, and stays that size: resizing a
            // layer surface every animation frame would stutter. Only the island itself takes
            // input (mask); the rest is transparent and clicks go to the windows below.
            anchors.top: true
            implicitWidth: Math.max(closedWidth, Theme.island.panelWidth) + Theme.island.fillet * 2
            implicitHeight: Theme.island.maxHeight
            color: "transparent"
            mask: Region { item: island }

            // Reserve only the closed island's height; the open menu floats over windows.
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: Theme.island.height

            // Hyprland layer rules match on this (see hypr/rules.lua).
            WlrLayershell.namespace: "qs-island"
            // OnDemand: the island gets the keyboard when the focus grab below hands it over or
            // you click into it (Escape, typing a Wi-Fi password), and never steals it otherwise.
            // Switching between None and Exclusive while the surface is mapped made Hyprland
            // drop the focus grab right after it started, closing the menu straight away.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            // Closes the menu when you click any other window or surface.
            HyprlandFocusGrab {
                windows: [window]
                active: window.open
                onCleared: root.panel = ""
            }

            IslandShape {
                id: island

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                color: Colors.surfaceTranslucent

                // The morph: width, height and corner radius animate between the closed pill
                // and the open menu, all on the same curve so the shape moves as one.
                bodyWidth: window.open ? Math.max(window.closedWidth, Theme.island.panelWidth) : window.closedWidth
                bodyHeight: Theme.island.height + (window.open ? menus.implicitHeight : 0)
                radius: window.open ? Theme.island.openRadius : Theme.island.height / 2

                Behavior on bodyWidth {
                    NumberAnimation { duration: Theme.anim.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized }
                }
                Behavior on bodyHeight {
                    NumberAnimation { duration: Theme.anim.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized }
                }
                Behavior on radius {
                    NumberAnimation { duration: Theme.anim.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized }
                }

                // Everything inside the island, clipped to its current size so the menus are
                // revealed as it grows.
                Item {
                    x: Theme.island.fillet
                    width: island.bodyWidth
                    height: island.bodyHeight
                    clip: true
                    focus: true
                    Keys.onEscapePressed: root.panel = ""

                    // Workspaces | time | status icons. Both sides get the width of the wider
                    // one, so the time sits exactly in the middle of the island.
                    Row {
                        id: topRow

                        // The dots get the same inset as the status icons have inside their button.
                        readonly property real sideWidth: Math.max(workspaces.implicitWidth + Theme.spacing.m, status.implicitWidth)

                        anchors.horizontalCenter: parent.horizontalCenter
                        height: Theme.island.height
                        spacing: Theme.spacing.s

                        Item {
                            width: topRow.sideWidth
                            height: parent.height

                            Workspaces {
                                id: workspaces
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacing.m
                                screen: window.modelData
                            }
                        }

                        IslandButton {
                            label: "Calendar and media"
                            active: window.panel === "today"
                            onActivated: root.toggle("today", window.modelData.name)

                            Clock {}
                        }

                        Item {
                            width: topRow.sideWidth
                            height: parent.height

                            IslandButton {
                                id: status
                                anchors.right: parent.right
                                label: "Quick settings"
                                active: window.panel === "settings"
                                onActivated: root.toggle("settings", window.modelData.name)

                                StatusIcons {}
                            }
                        }
                    }

                    // Both menus exist all the time; the open one fades in below the top row
                    // while the island grows around it.
                    Item {
                        id: menus

                        anchors.top: topRow.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.island.panelWidth
                        implicitHeight: window.panel === "today" ? today.implicitHeight
                                      : window.panel === "settings" ? settings.implicitHeight
                                      : 0

                        TodayPanel {
                            id: today
                            width: parent.width
                            opacity: window.panel === "today" ? 1 : 0
                            visible: opacity > 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        QuickSettings {
                            id: settings
                            width: parent.width
                            opacity: window.panel === "settings" ? 1 : 0
                            visible: opacity > 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }
                    }
                }
            }
        }
    }
}
