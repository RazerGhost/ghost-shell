import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets

// The island on one monitor (see Island.qml): the top row, and below it whichever menu,
// pop-up or hover view is shown.
PanelWindow {
    id: root

    required property ShellScreen modelData
    required property var island // Island.qml: panel, screenName, toggle(), reload*
    screen: modelData

    readonly property string panel: island.screenName === modelData.name ? island.panel : ""
    readonly property bool open: panel !== ""
    readonly property real closedWidth: topRow.implicitWidth + Theme.island.padding * 2

    // A small view opened by hovering: "media" (the player, over the live activity) or
    // "workspaces" (all workspaces as numbers and the minimized windows, over the dots). Unlike a menu it takes no keyboard and
    // closes when the pointer leaves the island.
    property string peek: ""
    // The dots, for the numbers on hover (named apart from WorkspaceNumbers' own `workspaces`).
    readonly property Item workspaceDots: workspaces
    // The notification pop-up, on the focused monitor while no menu is open.
    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === modelData.name
    readonly property Notification popup: !open && focusedScreen ? Notifications.current : null

    // A window asking for attention, once no notification is popping up.
    readonly property HyprlandToplevel attentionWindow: !open && focusedScreen && !Notifications.current
                                                        ? Windows.needsAttention : null

    // What's shown below the top row: a menu, a pop-up, a hover view ("peek-media", ...)
    // or nothing.
    readonly property string shown: open ? panel
                                  : island.reloadShown && focusedScreen ? "reload"
                                  : popup ? "notification"
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
        running: root.popupReady && root.popup !== null && !content.containsMouse
                 && root.popup.urgency !== NotificationUrgency.Critical
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
        running: root.attentionReady && root.attentionWindow !== null && !content.containsMouse
        onTriggered: Windows.attentionSeen()
    }

    // Hover the live activity or the workspace dots briefly to open their view; leave
    // the island to close it.
    Timer {
        interval: Theme.media.hoverDelay
        running: center.containsMouse && root.showMedia
        onTriggered: root.peek = "media"
    }

    Timer {
        interval: Theme.media.hoverDelay
        running: workspaces.hovered && !root.open
        onTriggered: root.peek = "workspaces"
    }

    Timer {
        interval: Theme.media.hoverDelay
        running: root.peek !== "" && !content.containsMouse
        onTriggered: root.peek = ""
    }

    // The window is as big as the island can get, and stays that size: resizing a
    // layer surface every animation frame would stutter. Only the island itself takes
    // input (mask); the rest is transparent and clicks go to the windows below.
    anchors.top: true
    // As wide as the screen: the wallpaper picker spans it.
    implicitWidth: modelData.width
    implicitHeight: Theme.island.maxHeight
    color: "transparent"
    mask: Region { item: shape }

    // Reserve only the closed island's height; the open menu floats over windows.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.island.height

    // Hyprland layer rules match on this (see hypr/rules.lua).
    WlrLayershell.namespace: "qs-island"
    // The keyboard only while a menu is open (Escape, typing a Wi-Fi password). Closed,
    // None: with OnDemand, merely moving the pointer over the island gave it the keyboard,
    // and clicking back into the window didn't take it back (Hyprland still counted that
    // window as focused). Not Exclusive when open: switching between None and Exclusive
    // made Hyprland drop the focus grab right after it started, closing the menu at once.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // "Keep awake" in quick settings: Hyprland holds off idling while a visible surface asks it
    // to, and the island is always visible.
    IdleInhibitor {
        window: root
        enabled: KeepAwake.on
    }

    // Closes the menu when you click any other window or surface.
    HyprlandFocusGrab {
        windows: [root]
        active: root.open
        onCleared: root.island.panel = ""
    }

    // One view below the top row: a menu, a pop-up or a hover view. All of them exist all the
    // time; the shown one fades in while the island grows around it. `extraHeight` is room the
    // content's margins take below it.
    component MenuSlot: Item {
        property bool shown
        property real extraHeight: 0

        width: parent.width
        implicitHeight: (children[0]?.implicitHeight ?? 0) + extraHeight
        opacity: shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.normal }
        }
    }

    IslandShape {
        id: shape

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: Theme.island.offset // under the webcam
        color: Colors.surfaceTranslucent

        // The morph: width, height and corner radius animate between the closed pill
        // and the open menu, all on the same curve so the shape moves as one.
        bodyWidth: root.expanded ? Math.max(root.closedWidth, root.menuWidth) : root.closedWidth
        bodyHeight: Theme.island.height + (root.expanded ? menus.implicitHeight : 0)
        radius: root.expanded ? Theme.island.openRadius : Theme.island.height / 2

        Behavior on bodyWidth {
            MorphAnimation {}
        }
        Behavior on bodyHeight {
            MorphAnimation {}
        }
        Behavior on radius {
            MorphAnimation {}
        }

        // Everything inside the island, clipped to its current size so the menus are
        // revealed as it grows. A MouseArea to know whether the pointer is over the island
        // (hover reaches it through its children too). Clicks go to the buttons inside.
        MouseArea {
            id: content

            x: Theme.island.fillet
            width: shape.bodyWidth
            height: shape.bodyHeight
            clip: true
            focus: true
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            Keys.onEscapePressed: root.island.panel = ""

            // Workspaces | time | status icons, symmetric (user's choice): both sides are as wide
            // as the wider group, each group centered on its side, so the time sits exactly in the
            // screen's middle, under the webcam. Groups keep their own spacing: spreading the
            // narrower one to match left odd gaps (two dots far apart).
            Row {
                id: topRow

                readonly property real sideWidth: Math.max(workspaces.implicitWidth, statusIcons.implicitWidth)

                anchors.horizontalCenter: parent.horizontalCenter
                height: Theme.island.height

                // Both sides are exactly sideWidth plus the buttons' padding.
                Item {
                    width: topRow.sideWidth + Theme.spacing.m * 2
                    height: parent.height

                    Workspaces {
                        id: workspaces
                        anchors.centerIn: parent
                        screen: root.modelData
                    }
                }

                // The time, or the live activity while music plays. Clicking opens whichever
                // is showing.
                IslandButton {
                    id: center

                    readonly property string menu: root.showMedia ? "media" : "today"

                    label: root.showMedia ? "Media" : "Calendar"
                    active: root.panel === menu
                    onActivated: root.island.toggle(menu, root.modelData.name)

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: root.showMedia ? activity.implicitWidth : clock.implicitWidth
                        implicitHeight: Theme.island.height

                        Behavior on implicitWidth {
                            MorphAnimation {}
                        }

                        Clock {
                            id: clock
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: root.showMedia ? 0 : 1
                            visible: opacity > 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }

                        MediaActivity {
                            id: activity
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: root.showMedia ? 1 : 0
                            visible: opacity > 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.anim.normal }
                            }
                        }
                    }
                }

                Item {
                    width: topRow.sideWidth + Theme.spacing.m * 2
                    height: parent.height

                    IslandButton {
                        id: status
                        anchors.centerIn: parent
                        label: "Quick settings"
                        active: root.panel === "settings"
                        onActivated: root.island.toggle("settings", root.modelData.name)

                        StatusIcons {
                            id: statusIcons
                        }
                    }
                }
            }

            // The views below the top row; the island takes the height of the shown one.
            Item {
                id: menus

                anchors.top: topRow.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.menuWidth
                implicitHeight: children.find(slot => slot.shown)?.implicitHeight ?? 0

                MenuSlot {
                    shown: root.shown === "attention"
                    extraHeight: Theme.spacing.s * 2

                    AttentionCard {
                        x: Theme.spacing.s
                        y: Theme.spacing.xs
                        width: parent.width - Theme.spacing.s * 2
                        window: root.attentionWindow
                        visible: root.attentionWindow !== null
                        onActivated: {
                            Windows.show(root.attentionWindow);
                            Windows.attentionSeen();
                        }
                    }
                }

                // "Shell reloaded", or why it couldn't (see Island.qml).
                MenuSlot {
                    shown: root.shown === "reload"
                    extraHeight: Theme.spacing.m * 2

                    Row {
                        x: Theme.spacing.l
                        y: Theme.spacing.m
                        width: parent.width - Theme.spacing.l * 2
                        spacing: Theme.spacing.m

                        MaterialIcon {
                            id: reloadIcon
                            icon: root.island.reloadError ? "error" : "check_circle"
                            color: root.island.reloadError ? Colors.m3error : Colors.m3primary
                        }

                        Column {
                            width: parent.width - reloadIcon.width - parent.spacing
                            spacing: Theme.spacing.xs

                            Text {
                                text: root.island.reloadError ? "Shell reload failed" : "Shell reloaded"
                                color: Colors.m3onSurface
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.normal
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: root.island.reloadError
                                color: Colors.m3onSurfaceVariant
                                font.family: Theme.font.mono
                                font.pixelSize: Theme.font.small
                                wrapMode: Text.Wrap
                                maximumLineCount: 6
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "notification"
                    extraHeight: Theme.spacing.s * 2

                    NotificationCard {
                        x: Theme.spacing.s
                        y: Theme.spacing.xs
                        width: parent.width - Theme.spacing.s * 2
                        notification: root.popup
                        visible: notification !== null
                        onReplyRequested: root.island.toggle("today", root.modelData.name)
                    }
                }

                // The hover player. Clicking it (outside its buttons) opens the media menu.
                MenuSlot {
                    shown: root.shown === "peek-media"
                    extraHeight: Theme.spacing.s

                    MediaCard {
                        x: Theme.spacing.s
                        width: parent.width - Theme.spacing.s * 2
                        color: "transparent"
                        visible: player !== null
                        onActivated: root.island.toggle("media", root.modelData.name)
                    }
                }

                MenuSlot {
                    shown: root.shown === "wallpaper"

                    WallpaperPanel {
                        width: parent.width
                    }
                }

                MenuSlot {
                    shown: root.shown === "emoji"

                    EmojiPanel {
                        width: parent.width
                        onPicked: emoji => {
                            root.island.panel = "";
                            Emoji.type(emoji);
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "clipboard"

                    ClipboardPanel {
                        width: parent.width
                        onPicked: entry => {
                            root.island.panel = "";
                            Clipboard.paste(entry);
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "power"

                    PowerPanel {
                        width: parent.width
                        onDone: root.island.panel = ""
                    }
                }

                // While hovering the dots: every workspace as a number, and the minimized windows.
                MenuSlot {
                    shown: root.shown === "peek-workspaces"
                    extraHeight: Theme.spacing.m * 2

                    Column {
                        x: Theme.spacing.l
                        y: Theme.spacing.s
                        width: parent.width - Theme.spacing.l * 2
                        spacing: Theme.spacing.m

                        WorkspaceNumbers {
                            anchors.horizontalCenter: parent.horizontalCenter
                            workspaces: root.workspaceDots
                        }

                        MinimizedList {
                            width: parent.width
                            visible: Windows.minimized.length > 0
                            onRestored: root.peek = ""
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "media"

                    MediaPanel {
                        width: parent.width
                    }
                }

                MenuSlot {
                    shown: root.shown === "today"

                    TodayPanel {
                        width: parent.width
                    }
                }

                MenuSlot {
                    shown: root.shown === "settings"

                    QuickSettings {
                        width: parent.width
                        onOpenMenu: menu => root.island.panel = menu
                    }
                }
            }
        }
    }
}
