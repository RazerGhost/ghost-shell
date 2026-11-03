import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets
import "IslandViews.js" as IslandViews

// The island on one monitor (see Island.qml): one shape under the webcam that shows only the time
// (or the playing music) and what needs attention (IslandAlerts.qml), and morphs into every menu
// (user's choice, 2026-11-03: workspaces, status icons and background apps in it, or in pills of
// their own, looked uneven). A click opens today (or media while music shows), a right-click
// quick settings, where the status icons and background apps are now. Switching workspaces shows
// the dots for a moment in the time's place; scrolling over the island steps through them. A
// shell reload shows "Reloaded" there too, or opens the island with why it failed (it was a card
// in the corner, among the notifications, for a day: it's the shell's own status, not one).
// Notifications pop up in the top-right corner (PopupStack.qml). Floating below the top edge, or
// attached to it (Settings' islandAttached; the dock and island editor).
PanelWindow {
    id: root

    required property ShellScreen modelData
    required property var island // Island.qml: panel, screenName, toggle()
    screen: modelData

    readonly property string panel: island.screenName === modelData.name ? island.panel : ""
    readonly property bool open: panel !== ""

    // A small view opened by hovering: "media" (the player, over the live activity). Unlike a
    // menu it takes no keyboard and closes when the pointer leaves the island.
    property string peek: ""

    // The workspace dots, for a moment after the workspace changes (and while the pointer is on
    // them, to click one), in the time's place.
    property bool flashing: false
    // "Reloaded" for a moment in the time's place after the shell reloads (Island.qml).
    readonly property bool showReloaded: island.reloadShown && island.reloadError === "" && !open
    readonly property bool showDots: flashing && !open && !showReloaded
    // While music plays the island shows the music instead of the time. Once it opens (hover
    // player or a menu) the time comes back, since the music is then shown below it.
    readonly property bool showMedia: Settings.values.islandMedia && Media.playing && !pill.expanded && !showDots && !showReloaded

    onOpenChanged: peek = ""

    // Hover the live activity briefly to open the player; leave the island to close it.
    Timer {
        interval: Theme.media.hoverDelay
        running: center.containsMouse && root.showMedia
        onTriggered: root.peek = "media"
    }

    Timer {
        interval: Theme.media.hoverDelay
        running: root.peek === "media" && !pill.hovered
        onTriggered: root.peek = ""
    }

    Timer {
        id: flashTimer
        interval: Theme.island.workspaceFlash
        onTriggered: {
            if (workspaces.hovered)
                restart();
            else
                root.flashing = false;
        }
    }

    Connections {
        target: workspaces
        function onActiveChanged(): void {
            root.flashing = true;
            flashTimer.restart();
        }
    }

    // The window spans the top of the screen as tall as the island can get, and stays that size:
    // resizing a layer surface every animation frame would stutter. Only the island takes input
    // (mask); the rest is transparent and clicks go to the windows below.
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Theme.island.maxHeight
    color: "transparent"
    mask: Region { item: pill }
    BackgroundEffect.blurRegion: pill.blur

    // Reserve only the closed island's band; open menus float over windows.
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

    // One view below the island's top row: a menu or a hover view. The shown one fades in while the
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

    IslandPill {
        id: pill

        shown: IslandViews.shown(root.panel, root.island.reloadShown && root.island.reloadError !== "", root.peek)
        hasFocus: root.open
        // Each menu's own width. Kept while closing, so the menu fading out doesn't reflow.
        onShownChanged: rememberWidth()
        // Also at the start: a menu kept open across a shell reload is already shown then.
        Component.onCompleted: rememberWidth()
        function rememberWidth(): void {
            if (shown !== "")
                openWidth = Theme.island.menuWidth(shown);
        }
        onCloseRequested: root.island.panel = ""

        // The time, the music, the workspace dots or "Reloaded", and the alerts beside them.
        row: IslandButton {
            id: center

            readonly property string menu: root.showMedia ? "media" : "today"

            label: root.showMedia ? "Media" : "Calendar"
            secondaryLabel: "Quick settings (Super+N)"
            details: alerts.summary
            active: root.open
            onActivated: root.island.toggle(menu, root.modelData.name)
            onSecondaryActivated: root.island.toggle("settings", root.modelData.name)
            onWheel: wheel => workspaces.scroll(wheel.angleDelta.y)

            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.showReloaded ? reloaded.implicitWidth
                             : root.showDots ? workspaces.implicitWidth
                             : root.showMedia ? activity.implicitWidth : clock.implicitWidth
                // Not animated here: the island's own width follows it with its morph (IslandPill),
                // and animating both made the island restart its morph every frame, trailing and
                // cutting off what grew.
                implicitHeight: Theme.island.height

                Clock {
                    id: clock
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: root.showMedia || root.showDots || root.showReloaded ? 0 : 1
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

                Row {
                    id: reloaded
                    anchors.centerIn: parent
                    spacing: Theme.spacing.xs
                    opacity: root.showReloaded ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.anim.normal }
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "check_circle"
                        font.pixelSize: Theme.icon.small
                        color: Colors.m3primary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Reloaded"
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.normal
                        font.weight: Font.DemiBold
                    }
                }

                // Always built (only invisible), so it follows the workspace while out of sight.
                Workspaces {
                    id: workspaces
                    anchors.horizontalCenter: parent.horizontalCenter
                    screen: root.modelData
                    opacity: root.showDots ? 1 : 0
                    // Out of screen readers' list while hidden; still follows the workspace.
                    visible: opacity > 0
                    enabled: root.showDots

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.anim.normal }
                    }
                }
            }

            IslandAlerts {
                id: alerts
            }
        }

        // Why the shell couldn't reload (the old shell keeps running).
        MenuSlot {
            shown: pill.shown === "reload"
            extraHeight: Theme.spacing.m * 2

            ReloadNotice {
                error: root.island.reloadError
            }
        }

        // The hover player. Clicking it (outside its buttons) opens the media menu.
        MenuSlot {
            shown: pill.shown === "peek-media"
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
            shown: pill.shown === "emoji"
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
            shown: pill.shown === "clipboard"
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
            shown: pill.shown === "media"
            content: Component {
                MediaPanel {
                    width: parent.width
                }
            }
        }

        MenuSlot {
            shown: pill.shown === "power"
            content: Component {
                PowerPanel {
                    width: parent.width
                    onDone: root.island.panel = ""
                }
            }
        }

        MenuSlot {
            shown: pill.shown === "settings"
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

        MenuSlot {
            shown: pill.shown === "today"
            content: Component {
                TodayPanel {
                    width: parent.width
                }
            }
        }

        MenuSlot {
            shown: pill.shown === "tray"
            content: Component {
                Tray {
                    width: parent.width
                    onDone: root.island.panel = ""
                }
            }
        }
    }
}
