import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets
import "IslandViews.js" as IslandViews

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
    // or nothing (IslandViews.js, tested).
    readonly property string shown: IslandViews.shown(panel, island.reloadShown && focusedScreen,
                                                      popup !== null, attentionWindow !== null, peek)
    readonly property bool expanded: shown !== ""
    readonly property real menuWidth: Theme.island.panelWidth
    // How long a notification pop-up (and the attention card) stays, from Settings (1-60 s).
    readonly property int popupTime: Math.min(60, Math.max(1, Number(Settings.values.notificationSeconds) || 5)) * 1000

    // While music plays the middle of the island shows the music instead of the time.
    // Once the island opens (hover player or a menu) the time comes back, since the
    // music is then shown below it.
    readonly property bool showMedia: Settings.values.islandMedia && Media.playing && !expanded

    onOpenChanged: peek = ""

    // Each pop-up stays Settings' notificationSeconds, paused while hovered; critical
    // ones stay until dismissed. popupReady dips for a moment when the pop-up changes,
    // which restarts the timer for the next one.
    property bool popupReady: true
    onPopupChanged: {
        popupReady = false;
        Qt.callLater(() => popupReady = true);
    }

    Timer {
        interval: root.popupTime
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
        interval: root.popupTime
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
    // As wide as the widest the island gets (a menu, or the closed island with many status
    // icons), plus its curves into the screen edge and its offset (Theme.island.offset), so the
    // island stays centered under the webcam. The closed width only changes when an icon comes
    // or goes, not every frame.
    implicitWidth: Math.max(Theme.island.panelWidth, closedWidth) + (Theme.island.fillet + Math.abs(Theme.island.offset)) * 2
    implicitHeight: Theme.island.maxHeight
    color: "transparent"
    mask: Region { item: shape }

    // Blur behind exactly the island's shape (ext-background-effect, which Hyprland 0.57 has;
    // replaces a layer rule that blurred every pixel above 30 % opacity): the body, rounded at
    // the bottom, and the strip along the screen edge with the fillets cut out of it (circles
    // centred where the fillets' arcs are).
    BackgroundEffect.blurRegion: Region {
        item: content
        bottomLeftRadius: shape.radius
        bottomRightRadius: shape.radius

        Region {
            x: shape.x
            width: shape.width
            height: Theme.island.fillet

            Region {
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
                x: shape.x - Theme.island.fillet
                width: Theme.island.fillet * 2
                height: Theme.island.fillet * 2
            }

            Region {
                shape: RegionShape.Ellipse
                intersection: Intersection.Subtract
                x: shape.x + shape.width - Theme.island.fillet
                width: Theme.island.fillet * 2
                height: Theme.island.fillet * 2
            }
        }
    }

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

    // One view below the top row: a menu, a pop-up or a hover view. The shown one fades in while
    // the island grows around it. `extraHeight` is room the content's margins take below it.
    // Light views are written inside the slot and always exist. The menus are a `content`
    // Component instead, built only while shown or fading out and freed after: built all the
    // time (on every screen), they held their memory and work for nothing (review 2026-10-29).
    component MenuSlot: Item {
        id: slot

        property bool shown
        property real extraHeight: 0
        property Component content: null

        width: parent.width
        // The last child: the content written inside, or the Loader when there's none.
        implicitHeight: (children[children.length - 1]?.implicitHeight ?? 0) + extraHeight
        opacity: shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.normal }
        }

        Loader {
            width: parent.width
            active: slot.content !== null && (slot.shown || slot.visible)
            sourceComponent: slot.content
        }
    }

    IslandShape {
        id: shape

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: Theme.island.offset // under the webcam
        color: Colors.surfaceTranslucent
        edgeColor: Colors.glassEdge

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
            // In a menu, the arrow keys move between its controls (to the nearest one that
            // way) and Tab, with nothing chosen yet, picks the first; Enter or Space use it.
            // Only the menu's own controls: Enter on the top row's clock or status icons would
            // close the menu and hand the keyboard back to the window.
            Keys.onPressed: event => {
                const keys = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down, Qt.Key_Tab];
                if (root.island.panel !== "" && keys.includes(event.key) && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
                    event.accepted = navigation.move(event.key);
            }

            ArrowNavigation {
                id: navigation
                area: menus
            }

            // Workspaces | time | status icons, symmetric (user's choice): both sides are as wide
            // as the wider group, so the time sits exactly in the screen's middle, under the
            // webcam. Each group sits against the island's end with the same padding, like a
            // status bar around a notch (user's choice: centered on its side, one workspace dot
            // floated in empty space next to the wider status icons). Groups keep their own
            // spacing: spreading the narrower one to match left odd gaps (two dots far apart).
            Row {
                id: topRow

                // The right side: the status icons and the background apps' arrow (when there are some).
                readonly property real sideWidth: Math.max(workspaces.implicitWidth,
                    statusIcons.implicitWidth + (trayButton.visible ? trayButton.implicitWidth : 0))

                anchors.horizontalCenter: parent.horizontalCenter
                height: Theme.island.height

                // Both sides are exactly sideWidth plus the buttons' padding.
                Item {
                    width: topRow.sideWidth + Theme.spacing.m * 2
                    height: parent.height

                    Workspaces {
                        id: workspaces
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.m // the status button's own padding
                        anchors.verticalCenter: parent.verticalCenter
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

                    // Apps running in the background (the system tray): an arrow at the outer right
                    // (user's choice) that opens their menu.
                    IslandButton {
                        id: trayButton
                        anchors.right: parent.right
                        visible: SystemTray.items.values.length > 0
                        label: "Background apps"
                        // The last app quit while its menu was open: close the empty menu.
                        onVisibleChanged: {
                            if (!visible && root.panel === "tray")
                                root.island.panel = "";
                        }
                        active: root.panel === "tray"
                        onActivated: root.island.toggle("tray", root.modelData.name)

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "keyboard_arrow_down"
                            font.pixelSize: Theme.icon.small
                            rotation: root.panel === "tray" ? 180 : 0

                            Behavior on rotation {
                                NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
                            }
                        }
                    }

                    IslandButton {
                        id: status
                        anchors.right: trayButton.visible ? trayButton.left : parent.right
                        anchors.verticalCenter: parent.verticalCenter
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

                    ReloadNotice {
                        error: root.island.reloadError
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
                    shown: root.shown === "emoji"
                    content: Component {
                        EmojiPanel {
                            width: parent.width
                            onPicked: emoji => {
                                root.island.panel = "";
                                Emoji.type(emoji);
                            }
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "clipboard"
                    content: Component {
                        ClipboardPanel {
                            width: parent.width
                            onPicked: entry => {
                                root.island.panel = "";
                                Clipboard.paste(entry);
                            }
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "tray"
                    content: Component {
                        Tray {
                            width: parent.width
                            onDone: root.island.panel = ""
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "power"
                    content: Component {
                        PowerPanel {
                            width: parent.width
                            onDone: root.island.panel = ""
                        }
                    }
                }

                // While hovering the ghost: every workspace as a number, and the minimized windows.
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
                    content: Component {
                        MediaPanel {
                            width: parent.width
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "today"
                    content: Component {
                        TodayPanel {
                            width: parent.width
                        }
                    }
                }

                MenuSlot {
                    shown: root.shown === "settings"
                    content: Component {
                        QuickSettings {
                            width: parent.width
                            onOpenMenu: menu => root.island.panel = menu
                            // Asked for edit mode (the customize menu): built now or already open.
                            function takeEdit(): void {
                                if (root.island.quickEdit) {
                                    editing = true;
                                    root.island.quickEdit = false;
                                }
                            }
                            Component.onCompleted: takeEdit()
                            Connections {
                                target: root.island
                                function onQuickEditChanged(): void {
                                    takeEdit();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
