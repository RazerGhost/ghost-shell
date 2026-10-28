import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets

// The bar: an "island" attached to the top edge of each monitor with the workspaces, the
// time and status icons. Clicking the time or the status icons morphs it into a menu:
// "today" (calendar) or "settings" (quick settings). While music plays, a "live activity"
// (cover and bars) takes the time's place: hovering it shows a small player (and the time
// again), clicking it or the player opens the "media" menu. Hovering the workspace dots shows
// the minimized windows. New notifications pop up from it on the focused monitor, one at a
// time. One menu is open at a time, on one monitor; click outside it or press Escape to close it.
Scope {
    id: root

    // "", "today", "settings", "media", "window", "power", "clipboard" or "wallpaper"
    property string panel: ""
    property string screenName: "" // the monitor the menu is open on
    // The window menu acts on the window that was focused when it opened.
    property HyprlandToplevel windowTarget: null

    function toggle(name: string, screen: string): void {
        if (panel === name && screenName === screen) {
            panel = "";
        } else {
            if (name === "window")
                windowTarget = Windows.active;
            panel = name;
            screenName = screen;
        }
    }

    // From Hyprland binds: qs ipc call island toggle settings (or: today, media, window, power,
    // clipboard, wallpaper)
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

            // A small view opened by hovering: "media" (the player, over the live activity) or
            // "minimized" (over the workspace dots). Unlike a menu it takes no keyboard and
            // closes when the pointer leaves the island.
            property string peek: ""
            // The notification pop-up, on the focused monitor while no menu is open.
            readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === modelData.name
            readonly property Notification popup: !open && focusedScreen ? Notifications.current : null

            // A window asking for attention, once no notification is popping up.
            readonly property HyprlandToplevel attentionWindow: !open && focusedScreen && !Notifications.current
                                                                ? Windows.needsAttention : null

            // What's shown below the top row: a menu, a pop-up, a hover view ("peek-media", ...)
            // or nothing.
            readonly property string shown: open ? panel : popup ? "notification"
                                          : attentionWindow ? "attention"
                                          : peek ? "peek-" + peek : ""
            readonly property bool expanded: shown !== ""
            // The wallpaper picker stretches across the whole top edge; other menus are narrow.
            readonly property real menuWidth: shown === "wallpaper" ? modelData.width - Theme.island.fillet * 2
                                                                    : Theme.island.panelWidth

            // While music plays the middle of the island shows the music instead of the time.
            // Once the island opens (hover player or a menu) the time comes back, since the
            // music is then shown below it.
            readonly property bool showMedia: Media.playing && !expanded

            onOpenChanged: peek = ""

            // Each pop-up stays Theme.notifications.timeout ms, paused while hovered; critical
            // ones stay until dismissed. popupReady dips for a moment when the pop-up changes,
            // which restarts the timer for the next one.
            property bool popupReady: true
            onPopupChanged: {
                popupReady = false;
                Qt.callLater(() => popupReady = true);
            }

            Timer {
                interval: Theme.notifications.timeout
                running: window.popupReady && window.popup !== null && !content.containsMouse
                         && window.popup.urgency !== NotificationUrgency.Critical
                onTriggered: Notifications.next()
            }

            // The attention card stays as long as a pop-up, the same way.
            property bool attentionReady: true
            onAttentionWindowChanged: {
                attentionReady = false;
                Qt.callLater(() => attentionReady = true);
            }

            Timer {
                interval: Theme.notifications.timeout
                running: window.attentionReady && window.attentionWindow !== null && !content.containsMouse
                onTriggered: Windows.attentionSeen()
            }

            // Hover the live activity or the workspace dots briefly to open their view; leave
            // the island to close it.
            Timer {
                interval: Theme.media.hoverDelay
                running: center.containsMouse && window.showMedia
                onTriggered: window.peek = "media"
            }

            Timer {
                interval: Theme.media.hoverDelay
                running: workspaces.hovered && Windows.minimized.length > 0 && !window.open
                onTriggered: window.peek = "minimized"
            }

            Timer {
                interval: Theme.media.hoverDelay
                running: window.peek !== "" && !content.containsMouse
                onTriggered: window.peek = ""
            }

            // The window is as big as the island can get, and stays that size: resizing a
            // layer surface every animation frame would stutter. Only the island itself takes
            // input (mask); the rest is transparent and clicks go to the windows below.
            anchors.top: true
            // As wide as the screen: the wallpaper picker spans it.
            implicitWidth: modelData.width
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
                bodyWidth: window.expanded ? Math.max(window.closedWidth, window.menuWidth) : window.closedWidth
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
                // revealed as it grows. A MouseArea to know whether the pointer is over the island
                // (hover reaches it through its children too), and for right-clicking the top
                // row to open the window menu. Left clicks go to the buttons inside.
                MouseArea {
                    id: content

                    x: Theme.island.fillet
                    width: island.bodyWidth
                    height: island.bodyHeight
                    clip: true
                    focus: true
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.y < Theme.island.height)
                            root.toggle("window", window.modelData.name);
                    }
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
                        width: window.menuWidth
                        implicitHeight: window.shown === "today" ? today.implicitHeight
                                      : window.shown === "settings" ? settings.implicitHeight
                                      : window.shown === "media" ? media.implicitHeight
                                      : window.shown === "window" ? windowMenu.implicitHeight
                                      : window.shown === "power" ? powerMenu.implicitHeight
                                      : window.shown === "clipboard" ? clipboard.implicitHeight
                                      : window.shown === "wallpaper" ? wallpapers.implicitHeight
                                      : window.shown === "notification" ? popupCard.implicitHeight + Theme.spacing.s * 2
                                      : window.shown === "attention" ? attentionCard.implicitHeight + Theme.spacing.s * 2
                                      : window.shown === "peek-media" ? peekCard.implicitHeight + Theme.spacing.s
                                      : window.shown === "peek-minimized" ? peekMinimized.implicitHeight + Theme.spacing.m * 2
                                      : 0

                        AttentionCard {
                            id: attentionCard
                            x: Theme.spacing.s
                            y: Theme.spacing.xs
                            width: parent.width - Theme.spacing.s * 2
                            window: window.attentionWindow
                            opacity: window.shown === "attention" ? 1 : 0
                            visible: opacity > 0 && window !== null
                            onActivated: {
                                Windows.focus(window);
                                Windows.attentionSeen();
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        NotificationCard {
                            id: popupCard
                            x: Theme.spacing.s
                            y: Theme.spacing.xs
                            width: parent.width - Theme.spacing.s * 2
                            notification: window.popup
                            opacity: window.shown === "notification" ? 1 : 0
                            visible: opacity > 0 && notification !== null

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        // The hover player. Clicking it (outside its buttons) opens the media menu.
                        MediaCard {
                            id: peekCard
                            x: Theme.spacing.s
                            width: parent.width - Theme.spacing.s * 2
                            color: "transparent"
                            onActivated: root.toggle("media", window.modelData.name)
                            opacity: window.shown === "peek-media" ? 1 : 0
                            visible: opacity > 0 && player !== null

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        WallpaperPanel {
                            id: wallpapers
                            width: window.menuWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: window.shown === "wallpaper" ? 1 : 0
                            visible: opacity > 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        ClipboardPanel {
                            id: clipboard
                            width: Theme.island.panelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: window.shown === "clipboard" ? 1 : 0
                            visible: opacity > 0
                            onPicked: entry => {
                                root.panel = "";
                                Clipboard.paste(entry);
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        PowerPanel {
                            id: powerMenu
                            width: Theme.island.panelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: window.shown === "power" ? 1 : 0
                            visible: opacity > 0
                            onDone: root.panel = ""

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        WindowPanel {
                            id: windowMenu
                            width: Theme.island.panelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            target: root.windowTarget
                            opacity: window.shown === "window" ? 1 : 0
                            visible: opacity > 0
                            onDone: root.panel = ""

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        // The minimized windows, while hovering the workspace dots.
                        MinimizedList {
                            id: peekMinimized
                            x: Theme.spacing.l
                            y: Theme.spacing.s
                            width: parent.width - Theme.spacing.l * 2
                            opacity: window.shown === "peek-minimized" ? 1 : 0
                            visible: opacity > 0 && Windows.minimized.length > 0
                            onRestored: window.peek = ""

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        MediaPanel {
                            id: media
                            width: Theme.island.panelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: window.shown === "media" ? 1 : 0
                            visible: opacity > 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        TodayPanel {
                            id: today
                            width: Theme.island.panelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: window.panel === "today" ? 1 : 0
                            visible: opacity > 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        QuickSettings {
                            id: settings
                            width: Theme.island.panelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            onOpenMenu: menu => root.panel = menu
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
