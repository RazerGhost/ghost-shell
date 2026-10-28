import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme

// The bar: an "island" attached to the top edge of each monitor with the workspaces, the
// time and status icons. Clicking the time or the status icons morphs it into a menu:
// "today" (calendar) or "settings" (quick settings). While music plays, a "live activity"
// (cover and bars) takes the time's place: hovering it shows a small player (and the time
// again), clicking it or the player opens the "media" menu. One menu is open at a time, on one
// monitor; click outside it or press Escape to close it.
Scope {
    id: root

    property string panel: ""      // "", "today", "settings" or "media"
    property string screenName: "" // the monitor the menu is open on

    function toggle(name: string, screen: string): void {
        if (panel === name && screenName === screen) {
            panel = "";
        } else {
            panel = name;
            screenName = screen;
        }
    }

    // From Hyprland binds: qs ipc call island toggle settings (or: today, media)
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

            // The small player shown while hovering the live activity. Unlike a menu it takes
            // no keyboard and closes when the pointer leaves the island.
            property bool peek: false
            // What's shown below the top row: a menu, the hover player ("peek") or nothing.
            readonly property string shown: open ? panel : peek ? "peek" : ""
            readonly property bool expanded: shown !== ""

            // While music plays the middle of the island shows the music instead of the time.
            // Once the island opens (hover player or a menu) the time comes back, since the
            // music is then shown below it.
            readonly property bool showMedia: Media.playing && !expanded

            onOpenChanged: peek = false

            // Hover the live activity briefly to open the player; leave the island to close it.
            Timer {
                interval: Theme.media.hoverDelay
                running: center.containsMouse && window.showMedia
                onTriggered: window.peek = true
            }

            Timer {
                interval: Theme.media.hoverDelay
                running: window.peek && !content.containsMouse
                onTriggered: window.peek = false
            }

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
                bodyWidth: window.expanded ? Math.max(window.closedWidth, Theme.island.panelWidth) : window.closedWidth
                bodyHeight: Theme.island.height + (window.expanded ? menus.implicitHeight : 0)
                radius: window.expanded ? Theme.island.openRadius : Theme.island.height / 2

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
                // revealed as it grows. A MouseArea only to know whether the pointer is over the
                // island (hover reaches it through its children too); it takes no clicks.
                MouseArea {
                    id: content

                    x: Theme.island.fillet
                    width: island.bodyWidth
                    height: island.bodyHeight
                    clip: true
                    focus: true
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
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

                        // The time, or the live activity while music plays. Clicking opens whichever
                        // is showing.
                        IslandButton {
                            id: center

                            readonly property string menu: window.showMedia ? "media" : "today"

                            label: window.showMedia ? "Media" : "Calendar"
                            active: window.panel === menu
                            onActivated: root.toggle(menu, window.modelData.name)

                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: window.showMedia ? activity.implicitWidth : clock.implicitWidth
                                implicitHeight: Theme.island.height

                                Behavior on implicitWidth {
                                    NumberAnimation { duration: Theme.anim.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized }
                                }

                                Clock {
                                    id: clock
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    opacity: window.showMedia ? 0 : 1
                                    visible: opacity > 0

                                    Behavior on opacity {
                                        NumberAnimation { duration: Theme.anim.normal }
                                    }
                                }

                                MediaActivity {
                                    id: activity
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    opacity: window.showMedia ? 1 : 0
                                    visible: opacity > 0

                                    Behavior on opacity {
                                        NumberAnimation { duration: Theme.anim.normal }
                                    }
                                }
                            }
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

                    // All menus exist all the time; the shown one fades in below the top row
                    // while the island grows around it.
                    Item {
                        id: menus

                        anchors.top: topRow.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.island.panelWidth
                        implicitHeight: window.shown === "today" ? today.implicitHeight
                                      : window.shown === "settings" ? settings.implicitHeight
                                      : window.shown === "media" ? media.implicitHeight
                                      : window.shown === "peek" ? peekCard.implicitHeight + Theme.spacing.s
                                      : 0

                        // The hover player. Clicking it (outside its buttons) opens the media menu.
                        MediaCard {
                            id: peekCard
                            x: Theme.spacing.s
                            width: parent.width - Theme.spacing.s * 2
                            color: "transparent"
                            onActivated: root.toggle("media", window.modelData.name)
                            opacity: window.shown === "peek" ? 1 : 0
                            visible: opacity > 0 && player !== null

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        MediaPanel {
                            id: media
                            width: parent.width
                            opacity: window.shown === "media" ? 1 : 0
                            visible: opacity > 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

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
