import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.wallpaper
import qs.widgets
import "IslandViews.js" as IslandViews
import "../services/FileUrl.js" as FileUrl

// The island on one monitor (see Island.qml): one shape under the webcam that shows only the time
// (or the playing music) and what needs attention (IslandAlerts.qml), and morphs into every menu
// (user's choice, 2026-11-03: workspaces, status icons and background apps in it, or in pills of
// their own, looked uneven). A click opens today (or media while music shows), a right-click
// quick settings, where the status icons and background apps are now, a middle-click plays or
// pauses the music. Switching workspaces shows the dots for a moment in the time's place.
// Resting the pointer on it widens it: the workspace dots on its left, Wi-Fi and the battery on
// its right, only shown (clicks there open the menus too). The wheel sets the volume (Shift: the brightness; over the dots or with Ctrl:
// workspaces; over the music's cover: tracks), its alerts lead where they say, and files dropped
// on it go to your phone or, with LocalSend, another device (SendPanel). A
// shell reload shows "Reloaded" there too, or opens the island with why it failed (it was a card
// in the corner, among the notifications, for a day: it's the shell's own status, not one).
// New notifications pop out of it one at a time, then a window asking for attention (user's
// choice, 2026-11-04: the top-right corner, for a day, didn't fit the one island). Floating
// below the top edge, or attached to it (Settings' islandAttached; the dock and island editor).
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

    // The notification pop-up, on the focused monitor (the first one until Hyprland says which)
    // while no menu is open and the screen isn't locked (they wait, and show once it's unlocked),
    // then a window asking for attention.
    readonly property bool focusedScreen: (Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name) === modelData.name
    // Not while locked, greeting, or logging out / shutting down (under its dimmed screen a pop-up
    // would use up its time unseen).
    readonly property bool canPop: !open && focusedScreen && !Session.locked && !island.welcomeShown && Session.ending === ""
    readonly property Notification popup: canPop ? Notifications.current : null
    readonly property HyprlandToplevel attentionWindow: canPop && !Notifications.current ? Windows.needsAttention : null
    // How long each stays, from Settings (it offers 3-30 s; kept within 1-60 should the file say
    // otherwise). Paused while the pointer is on the island; critical notifications stay until
    // dismissed, going to the back of the line after their time while others wait.
    readonly property int popupTime: Math.min(60, Math.max(1, Number(Settings.values.notificationSeconds) || 5)) * 1000

    // Each new one gets its full time: `ready` dips for a moment when it changes, restarting the
    // timer.
    property bool popupReady: true
    onPopupChanged: {
        popupReady = false;
        Qt.callLater(() => popupReady = true);
    }
    readonly property bool popupCritical: popup?.urgency === NotificationUrgency.Critical
    Timer {
        interval: root.popupTime
        running: root.popupReady && root.popup !== null && !pill.hovered
                 && (!root.popupCritical || Notifications.queue.filter(n => n !== null).length > 1)
        onTriggered: root.popupCritical ? Notifications.later(root.popup) : Notifications.done(root.popup)
    }

    property bool attentionReady: true
    onAttentionWindowChanged: {
        attentionReady = false;
        Qt.callLater(() => attentionReady = true);
    }
    Timer {
        interval: root.popupTime
        running: root.attentionReady && root.attentionWindow !== null && !pill.hovered
        onTriggered: Windows.attentionSeen()
    }

    // The workspace dots, for a moment after the workspace changes (and while the pointer is on
    // them, to click one), in the time's place.
    property bool flashing: false
    // "Reloaded" for a moment in the time's place after the shell reloads (Island.qml).
    readonly property bool showReloaded: island.reloadShown && island.reloadError === "" && !open
    readonly property bool showDots: flashing && !open && !showReloaded && !wide && !showDrop
    // Files dragged over the island: "Send to <phone>" in the time's place.
    readonly property bool showDrop: fileDrop.containsDrag && !open
    // While music plays the island shows the music instead of the time. Once it opens (hover
    // player or a menu) the time comes back, since the music is then shown below it.
    readonly property bool showMedia: Settings.values.islandMedia && Media.playing && !pill.expanded && !showDots && !showReloaded && !showDrop

    // The pointer has rested on the island (Theme.island.wideDelay): it widens, the workspace dots
    // on the left and Wi-Fi and the battery on the right, while nothing opens below it but the
    // hover player.
    property bool rested: false
    // Both sides as wide as the wider, so the time stays in the middle, under the webcam.
    readonly property real sideWidth: Math.max(sideDots.implicitWidth, status.implicitWidth) + Theme.spacing.s
    readonly property bool wide: rested && !open && !showDrop && (pill.shown === "" || pill.shown === "peek-media")
    Timer {
        interval: Theme.island.wideDelay
        running: pill.hovered && !root.rested
        onTriggered: root.rested = true
    }
    Connections {
        target: pill
        function onHoveredChanged(): void {
            if (!pill.hovered)
                root.rested = false;
        }
    }

    // The wheel on the island (user's choice): the volume; with Shift the brightness; over the
    // workspace dots or with Ctrl the workspaces; over the music's cover (or the time beside the
    // hover player) the tracks, a notch each.
    // A touchpad's natural scrolling (`inverted`) is turned back for the levels, so swiping up
    // turns them up.
    property real trackScroll: 0
    function scrolled(wheel: var): void {
        const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
        const level = (wheel.inverted ? -delta : delta) / 120;
        if ((wheel.modifiers & Qt.ControlModifier) || sideDots.hovered) {
            workspaces.scroll(delta);
        } else if (wheel.modifiers & Qt.ShiftModifier) {
            Brightness.change(level * Theme.island.brightnessStep);
        } else if (centerHover.hovered && (root.showMedia || root.peek === "media")) {
            trackScroll += delta;
            if (Math.abs(trackScroll) >= 120) {
                if (trackScroll > 0)
                    Media.previous();
                else
                    Media.next();
                trackScroll = 0;
            }
        } else {
            Audio.setVolume(Audio.volume + level * Theme.island.volumeStep);
        }
    }

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
    // The glass is drawn here (backdrop below) while there's a wallpaper picture; Hyprland's blur
    // only without one. One pixel in the transparent corner then: an empty region made Hyprland
    // 0.57 blur the whole window (NOTES).
    BackgroundEffect.blurRegion: backdrop.drawn ? corner : pill.blur
    Region {
        id: corner
        width: 1
        height: 1
    }

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

    // Files dropped on the island: the send menu asks where (your phone or, with LocalSend, another
    // device), or they go straight to the phone without LocalSend (Island.offerSend). Only files:
    // text and links are refused.
    DropArea {
        id: fileDrop
        anchors.fill: pill
        enabled: !root.open
        onEntered: drag => {
            if (!drag.hasUrls) {
                drag.accepted = false;
                return;
            }
            Phone.refresh(); // its name for the hint
        }
        onDropped: drop => {
            const paths = drop.urls.map(url => FileUrl.pathOf(url)).filter(path => path !== "");
            if (paths.length === 0)
                return;
            root.island.offerSend(paths, root.modelData.name);
            drop.accept(Qt.CopyAction);
        }
    }

    // The glass behind the island: the wallpaper, blurred and masked to the island's shape, like
    // the lock screen's (LockContent). Hyprland's blur cuts off in whole pixels, unsmoothed, and
    // the island blurs only the wallpaper (rules.lua's xray), so over a window its corners showed
    // stair-steps (user's find, 2026-11-05); the mask here is the shape as drawn, smoothed. The
    // window's top-left is the screen's, so the picture lines up with the wallpaper under it.
    Image {
        id: backdrop
        // Shown at all: a picture, and panels that aren't solid.
        readonly property bool drawn: status === Image.Ready && Colors.panelAlpha < 1
        width: root.modelData.width
        height: root.modelData.height
        visible: false
        source: Wallpaper.stillPath !== "" ? FileUrl.of(Wallpaper.stillPath) : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        cache: false // a live wallpaper's still frame always has the same name
    }

    MultiEffect {
        width: backdrop.width
        height: backdrop.height
        visible: backdrop.drawn
        source: backdrop
        blurEnabled: true
        blur: 1
        blurMax: Theme.lock.blur
        autoPaddingEnabled: false // padded, the mask was stretched and sat off the shape
        maskEnabled: true
        maskSource: backdropMask
        // The mask's own smoothing: by default any trace of the shape counts as inside, so the
        // glass ended in hard steps just past the smoothed edge.
        maskSpreadAtMin: 1
    }

    Item {
        id: backdropMask
        width: backdrop.width
        height: backdrop.height
        visible: false
        layer.enabled: true

        PillShape {
            x: pill.x + pill.outline.x
            y: pill.y + pill.outline.y
            attached: pill.outline.attached
            bodyWidth: pill.outline.bodyWidth
            bodyHeight: pill.outline.bodyHeight
            radius: pill.outline.radius
            color: "white"
        }
    }

    IslandPill {
        id: pill

        shown: IslandViews.shown(root.panel, root.island.reloadShown && root.island.reloadError !== "",
                                 root.island.welcomeShown && root.focusedScreen && !Notifications.fullscreenNow, root.popup !== null, root.attentionWindow !== null, root.peek)
        hasFocus: root.open
        // Each menu's own width. Kept while closing, so the menu fading out doesn't reflow.
        onShownChanged: rememberWidth()
        // Also at the start: a menu kept open across a shell reload is already shown then.
        Component.onCompleted: rememberWidth()
        // Never wider than the screen, less a margin each side (the wallpaper row at 1200 px on a
        // small screen, or at a larger shell size).
        function rememberWidth(): void {
            if (shown !== "")
                openWidth = Math.min(Theme.island.menuWidth(shown), root.width - Theme.spacing.l * 2);
        }
        onCloseRequested: root.island.panel = ""

        // The time, the music, the workspace dots or "Reloaded", and the alerts beside them.
        row: IslandButton {
            id: center

            readonly property string menu: root.showMedia ? "media" : "today"

            // The time first, so a screen reader says what the island shows.
            label: root.showMedia ? "Media" : clock.text + ", calendar"
            secondaryLabel: "Quick settings (Super+A)"
            middleLabel: Media.player ? "Play or pause" : ""
            details: [alerts.summary, "Scroll: volume, with Shift: brightness, with Ctrl: workspaces"].filter(text => text !== "").join(". ")
            active: root.open
            onActivated: root.island.toggle(menu, root.modelData.name)
            onSecondaryActivated: root.island.toggle("settings", root.modelData.name)
            onMiddleActivated: Media.playPause()
            onWheel: wheel => root.scrolled(wheel)

            // The workspace dots while the island is wide: only shown (user's choice: a click
            // anywhere on the island opens its menus, nothing that slid in under the pointer takes
            // it); the wheel over them steps through the workspaces.
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.sideWidth
                implicitHeight: Theme.island.height
                opacity: root.wide ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.anim.normal }
                }

                Workspaces {
                    id: sideDots
                    anchors.left: parent.left
                    screen: root.modelData
                    clickable: false
                }
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.showDrop ? dropHint.implicitWidth
                             : root.showReloaded ? reloaded.implicitWidth
                             : root.showDots ? workspaces.implicitWidth
                             : root.showMedia ? activity.implicitWidth : clock.implicitWidth
                // Not animated here: the island's own width follows it with its morph (IslandPill),
                // and animating both made the island restart its morph every frame, trailing and
                // cutting off what grew.
                implicitHeight: Theme.island.height

                IslandFade {
                    shown: !root.showMedia && !root.showDots && !root.showReloaded && !root.showDrop

                    Clock {
                        id: clock
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // The wheel here steps through the tracks while music shows: the cover, or the time
                // that takes its place while the hover player is open.
                HoverHandler {
                    id: centerHover
                }

                IslandFade {
                    shown: root.showMedia

                    MediaActivity {
                        id: activity
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // Files dragged over the island: where they'll go.
                IslandFade {
                    shown: root.showDrop

                    Row {
                        id: dropHint
                        anchors.centerIn: parent
                        spacing: Theme.spacing.xs

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "send_to_mobile"
                            font.pixelSize: Theme.icon.small
                            color: Colors.m3primary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Phone.localSend ? "Drop to send" : "Send to " + (Phone.phone?.name ?? "your phone")
                            color: Colors.m3onSurface
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.normal
                            font.weight: Font.DemiBold
                        }
                    }
                }

                IslandFade {
                    shown: root.showReloaded

                    Row {
                        id: reloaded
                        anchors.centerIn: parent
                        spacing: Theme.spacing.xs

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
                }

                // Always built (only invisible), so it follows the workspace while out of sight.
                IslandFade {
                    shown: root.showDots

                    Workspaces {
                        id: workspaces
                        anchors.horizontalCenter: parent.horizontalCenter
                        screen: root.modelData
                        enabled: root.showDots
                    }
                }
            }

            IslandAlerts {
                id: alerts
                onTodayRequested: part => root.island.openToday(part, root.modelData.name)
                onSettingsRequested: root.island.openPage("", root.modelData.name)
            }

            // Wi-Fi and the battery while the island is wide, only shown like the dots (the rest of the
            // status is in quick settings, a right-click away).
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.sideWidth
                implicitHeight: Theme.island.height
                opacity: root.wide ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.anim.normal }
                }

                Row {
                    id: status
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing.s

                    // Wi-Fi as signal bars (user's choice); wired, off or not connected as their icon.
                    SignalBars {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: NetworkStatus.signal >= 0
                    }

                    WifiIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: NetworkStatus.signal < 0
                        icon: NetworkStatus.icon
                        font.pixelSize: Theme.icon.small
                        Accessible.name: "Network: " + NetworkStatus.label
                        Accessible.ignored: false
                        Accessible.role: Accessible.StaticText
                    }

                    BatteryPill {
                        visible: Battery.present
                    }
                }
            }
        }

        MenuSlot {
            shown: pill.shown === "notification"
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

        MenuSlot {
            shown: pill.shown === "attention"
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

        // The greeting after an unlock. A click opens the today menu.
        MenuSlot {
            shown: pill.shown === "welcome"
            extraHeight: Theme.spacing.s

            WelcomeCard {
                x: Theme.spacing.s
                width: parent.width - Theme.spacing.s * 2
                first: root.island.welcomeFirst
                // Stays while the pointer is on it, like a notification.
                onContainsMouseChanged: root.island.holdWelcome(containsMouse)
                onActivated: {
                    root.island.welcomeShown = false;
                    root.island.toggle("today", root.modelData.name);
                }
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
            shown: pill.shown === "wallpaper"
            content: Component {
                WallpaperPanel {
                    width: parent.width
                    active: true
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
            shown: pill.shown === "send"
            content: Component {
                SendPanel {
                    width: parent.width
                    paths: root.island.sendPaths
                    onDone: root.island.panel = ""
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
                    // Only quick settings on the screen it's opened on: one still fading out on
                    // another screen would take it.
                    function takeEdit(): void {
                        if (root.island.quickEdit && root.panel === "settings") {
                            editing = true;
                            root.island.quickEdit = false;
                        }
                    }
                    // Asked for one of its pages (`island page`): the same, for the page.
                    function takePage(): void {
                        if (root.island.quickPage !== "" && root.panel === "settings") {
                            page = root.island.quickPage;
                            root.island.quickPage = "";
                        }
                    }
                    Component.onCompleted: {
                        takeEdit();
                        takePage();
                    }
                    Connections {
                        target: root.island
                        function onQuickEditChanged(): void {
                            takeEdit();
                        }
                        function onQuickPageChanged(): void {
                            takePage();
                        }
                    }
                }
            }
        }

        MenuSlot {
            shown: pill.shown === "today"
            content: Component {
                TodayPanel {
                    id: today
                    width: parent.width
                    // Asked for one of its parts (the island's timer): built now or already open.
                    function takePart(): void {
                        if (root.island.todayPart !== "" && root.panel === "today") {
                            today.openPart(root.island.todayPart);
                            root.island.todayPart = "";
                        }
                    }
                    Component.onCompleted: takePart()
                    Connections {
                        target: root.island
                        function onTodayPartChanged(): void {
                            today.takePart();
                        }
                    }
                }
            }
        }

    }
}
