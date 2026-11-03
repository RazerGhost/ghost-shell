import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets
import "IslandViews.js" as IslandViews

// The island on one monitor (see Island.qml), as three pills (user's choice, 2026-11-03; it was
// one shape with everything in it): the workspaces on the left, the time (or the playing music)
// in the middle, the status icons on the right. The middle one opens today, media, clipboard and
// emoji; the right one quick settings, background apps and power; the left one shows every
// workspace and the minimized windows while hovered. Notifications pop up in the top-right
// corner instead (PopupStack.qml). Floating below the top edge, or attached to it (Settings'
// islandAttached; the dock and island editor).
PanelWindow {
    id: root

    required property ShellScreen modelData
    required property var island // Island.qml: panel, screenName, toggle()
    screen: modelData

    readonly property string panel: island.screenName === modelData.name ? island.panel : ""
    readonly property bool open: panel !== ""

    // A small view opened by hovering: "media" (the player, over the live activity) or
    // "workspaces" (all workspaces as numbers and the minimized windows, over the dots). Unlike a
    // menu it takes no keyboard and closes when the pointer leaves its pill.
    property string peek: ""
    // The dots, for the numbers on hover (named apart from WorkspaceNumbers' own `workspaces`).
    readonly property Item workspaceDots: workspaces

    // While music plays the middle pill shows the music instead of the time. Once it opens
    // (hover player or a menu) the time comes back, since the music is then shown below it.
    readonly property bool showMedia: Settings.values.islandMedia && Media.playing && !middle.expanded

    onOpenChanged: peek = ""

    // Hover the live activity or the workspace dots briefly to open their view; leave the pill
    // to close it.
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
        running: (root.peek === "media" && !middle.hovered) || (root.peek === "workspaces" && !left.hovered)
        onTriggered: root.peek = ""
    }

    // The window spans the top of the screen as tall as a pill can get, and stays that size:
    // resizing a layer surface every animation frame would stutter. Only the pills take input
    // (mask); the rest is transparent and clicks go to the windows below.
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Theme.island.maxHeight
    color: "transparent"
    mask: Region {
        item: left
        Region { item: middle }
        Region { item: right }
    }
    BackgroundEffect.blurRegion: Region {
        regions: [left.blur, middle.blur, right.blur]
    }

    // Reserve only the closed pills' band; open menus float over windows.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.island.reserved

    // Hyprland layer rules match on this (see hypr/rules.lua).
    WlrLayershell.namespace: "qs-island"
    // The keyboard only while a menu is open (Escape, typing a Wi-Fi password). Closed, None:
    // with OnDemand, merely moving the pointer over the island gave it the keyboard, and clicking
    // back into the window didn't take it back (Hyprland still counted that window as focused).
    // Not Exclusive when open: switching between None and Exclusive made Hyprland drop the focus
    // grab right after it started, closing the menu at once.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // "Keep awake" in quick settings: Hyprland holds off idling while a visible surface asks it
    // to, and the island is always visible. Also while recording the screen: a recording without
    // input would otherwise dim, lock (recording the lock screen) and on battery suspend.
    IdleInhibitor {
        window: root
        enabled: KeepAwake.on || Recorder.recording
    }

    // Closes the menu when you click any other window or surface.
    HyprlandFocusGrab {
        windows: [root]
        active: root.open
        onCleared: root.island.panel = ""
    }

    // One view below a pill's top row: a menu or a hover view. The shown one fades in while the
    // pill grows around it. `extraHeight` is room the content's margins take below it. Light
    // views are written inside the slot and always exist. The menus are a `content` Component
    // instead, built only while shown or fading out and freed after: built all the time (on
    // every screen), they held their memory and work for nothing (review 2026-10-29).
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

    // The workspaces. Hovering them shows every workspace as a number, and the minimized windows.
    IslandPill {
        id: left

        side: "left"
        shown: IslandViews.shown("left", root.panel, root.peek === "workspaces" ? "workspaces" : "")
        onCloseRequested: root.island.panel = ""

        row: Workspaces {
            id: workspaces
            anchors.verticalCenter: parent.verticalCenter
            screen: root.modelData
        }

        MenuSlot {
            shown: left.shown === "peek-workspaces"
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
    }

    // The time, or the live activity while music plays. Clicking opens whichever is showing.
    IslandPill {
        id: middle

        side: "center"
        shown: IslandViews.shown("center", root.panel, root.peek === "media" ? "media" : "")
        hasFocus: IslandViews.side(root.panel) === "center"
        onCloseRequested: root.island.panel = ""

        row: IslandButton {
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

        // The hover player. Clicking it (outside its buttons) opens the media menu.
        MenuSlot {
            shown: middle.shown === "peek-media"
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
            shown: middle.shown === "emoji"
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
            shown: middle.shown === "clipboard"
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
            shown: middle.shown === "media"
            content: Component {
                MediaPanel {
                    width: parent.width
                }
            }
        }

        MenuSlot {
            shown: middle.shown === "today"
            content: Component {
                TodayPanel {
                    width: parent.width
                }
            }
        }
    }

    // The status icons (quick settings) and, while apps run in the background, an arrow at the
    // outer end that opens their menu.
    IslandPill {
        id: right

        side: "right"
        shown: IslandViews.shown("right", root.panel, "")
        hasFocus: IslandViews.side(root.panel) === "right"
        onCloseRequested: root.island.panel = ""

        row: [
            IslandButton {
                id: status
                anchors.verticalCenter: parent.verticalCenter
                label: "Quick settings"
                active: root.panel === "settings"
                onActivated: root.island.toggle("settings", root.modelData.name)

                StatusIcons {}
            },
            IslandButton {
                id: trayButton
                anchors.verticalCenter: parent.verticalCenter
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
        ]

        MenuSlot {
            shown: right.shown === "tray"
            content: Component {
                Tray {
                    width: parent.width
                    onDone: root.island.panel = ""
                }
            }
        }

        MenuSlot {
            shown: right.shown === "power"
            content: Component {
                PowerPanel {
                    width: parent.width
                    onDone: root.island.panel = ""
                }
            }
        }

        MenuSlot {
            shown: right.shown === "settings"
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
