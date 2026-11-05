import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "QuickItems.js" as QuickItems
import "../services/PowerModes.js" as PowerModes
import "../widgets/OrderedList.js" as OrderedList

// The quick settings menu: the status icons and battery, tiles, volume and brightness sliders.
// The Wi-Fi, Bluetooth and Sound tiles slide in a page of their own, like Android.
Item {
    id: root

    property string page: "main" // "main", "wifi", "bluetooth", "sound", "phone", "display", "vpn", "system" or "apps"

    // A button here opens another island menu ("power"), or closes the island ("").
    signal openMenu(string menu)
    readonly property int padding: Theme.spacing.l

    // Your tiles and round buttons, in your order (Settings' quickTiles and quickToggles), and
    // edit mode, where they're added, removed and moved on the panel itself, like Android.
    property bool editing: false
    // The sound outputs unfolded under the volume slider (folded each time quick settings opens).
    property bool devicesOpen: false
    readonly property var tileList: QuickItems.shown(Settings.values.quickTiles, QuickItems.tiles, QuickItems.defaultTiles)
    readonly property var toggleList: QuickItems.shown(Settings.values.quickToggles, QuickItems.toggles, QuickItems.defaultToggles)
    // Each one's name, icon and control (a component below), for its slot, edit mode's labels and
    // its "Available" chips.
    readonly property var info: ({
        wifi: { icon: "wifi", title: "Wi-Fi", control: wifiTile },
        bluetooth: { icon: "bluetooth", title: "Bluetooth", control: bluetoothTile },
        sound: { icon: "volume_up", title: "Sound", control: soundTile },
        power: { icon: "balance", title: "Power mode", control: powerTile },
        phone: { icon: "smartphone", title: "Phone", control: phoneTile },
        display: { icon: "desktop_windows", title: "Display", control: displayTile },
        vpn: { icon: "vpn_key", title: "VPN", control: vpnTile },
        mic: { icon: "mic", title: "Microphone", control: micToggle },
        dnd: { icon: "do_not_disturb_on", title: "Do Not Disturb", control: dndToggle },
        nightlight: { icon: "nightlight", title: "Night light", control: nightToggle },
        awake: { icon: "coffee", title: "Keep awake", control: awakeToggle },
        game: { icon: "sports_esports", title: "Game mode", control: gameToggle },
        airplane: { icon: "flight", title: "Airplane mode", control: airplaneToggle },
        dark: { icon: "dark_mode", title: "Dark mode", control: darkToggle },
        record: { icon: "radio_button_checked", title: "Record the screen", control: recordToggle },
        screenshot: { icon: "screenshot_region", title: "Screenshot", control: screenshotToggle },
        wallpaper: { icon: "wallpaper", title: "Wallpaper", control: wallpaperToggle },
        timer: { icon: "timer", title: "Timer", control: timerToggle },
        focus: { icon: "self_improvement", title: "Focus", control: focusToggle },
        hotspot: { icon: "wifi_tethering", title: "Hotspot", control: hotspotToggle },
        layout: { icon: "keyboard", title: "Keyboard layout", control: layoutToggle },
        picker: { icon: "colorize", title: "Color picker", control: pickerToggle },
        nearby: { icon: "share", title: "Nearby sharing", control: nearbyToggle }
    })

    // The island grows and shrinks to fit the current page.
    implicitHeight: (page === "wifi" ? wifiPage : page === "bluetooth" ? bluetoothPage
                     : page === "sound" ? soundPage : page === "phone" ? phonePage : page === "display" ? displayPage : page === "vpn" ? vpnPage
                     : page === "system" ? systemPage : page === "apps" ? appsPage : mainPage).implicitHeight
                    + padding
    clip: true // pages slide in from the side

    // Start on the main page next time.
    onVisibleChanged: {
        if (!visible) {
            page = "main";
            editing = false;
        }
    }

    // Escape on a page goes back to the main page; on the main page it closes the menu (the
    // island handles it). A page opened with the mouse leaves the keyboard on the island
    // itself, outside this menu, so take it then: the arrow keys still reach the island.
    Keys.onEscapePressed: event => {
        event.accepted = page !== "main" || editing;
        page = "main";
        editing = false;
    }
    onPageChanged: {
        if (page === "main")
            return;
        for (let item = Window.activeFocusItem; item; item = item.parent) {
            if (item === root)
                return;
        }
        forceActiveFocus();
    }

    // Each tile and round button, by id (the edit mode places them, in your order).
    Component {
        id: wifiTile

        Tile {
            width: tileGrid.widthOf("wifi")
            icon: NetworkStatus.icon
            title: "Wi-Fi"
            subtitle: NetworkStatus.label
            active: NetworkStatus.wired || NetworkStatus.wifiNetwork !== null
            hasPage: true
            onClicked: root.page = "wifi"
        }
    }

    Component {
        id: bluetoothTile

        Tile {
            width: tileGrid.widthOf("bluetooth")
            icon: BluetoothStatus.icon
            title: "Bluetooth"
            subtitle: BluetoothStatus.label
            active: BluetoothStatus.enabled
            hasPage: true
            onClicked: root.page = "bluetooth"
        }
    }

    Component {
        id: soundTile

        Tile {
            width: tileGrid.widthOf("sound")
            icon: Audio.icon
            title: "Sound"
            subtitle: Audio.sink ? Audio.deviceName(Audio.sink) : "No output"
            active: !Audio.muted
            hasPage: true
            onClicked: root.page = "sound"
        }
    }

    Component {
        id: phoneTile

        // KDE Connect (the phone module): the connected phone and its battery.
        Tile {
            width: tileGrid.widthOf("phone")
            icon: "smartphone"
            title: Phone.phone?.name ?? "Phone"
            subtitle: Phone.label
            active: Phone.phone !== null
            hasPage: true
            onClicked: root.page = "phone"
        }
    }

    Component {
        id: displayTile

        // The screen: its refresh rate, and night light while it's on (services/Display.qml).
        Tile {
            width: tileGrid.widthOf("display")
            icon: "desktop_windows"
            title: "Display"
            subtitle: [Display.lowered ? Display.lowest + " Hz on battery" : Display.chosenRate > 0 ? Display.chosenRate + " Hz" : "",
                       NightLight.on ? "Night light" : ""].filter(s => s).join(" · ")
            active: NightLight.on
            hasPage: true
            onClicked: root.page = "display"
        }
    }

    Component {
        id: vpnTile

        // The connected VPN, or the one the switch would connect (services/NetworkExtras.qml).
        Tile {
            width: tileGrid.widthOf("vpn")
            icon: "vpn_key"
            title: "VPN"
            subtitle: NetworkExtras.activeVpn ? NetworkExtras.activeVpn.name
                    : NetworkExtras.lastVpn ? "Off · " + NetworkExtras.lastVpn.name : "None set up"
            active: NetworkExtras.activeVpn !== null
            hasPage: true
            onClicked: root.page = "vpn"
        }
    }

    Component {
        id: powerTile

        // power-profiles-daemon. Cycles power saver -> balanced -> performance.
        Tile {
            width: tileGrid.widthOf("power")

            // Some machines have no performance profile; skip it when cycling there.
            readonly property list<int> profiles: PowerProfiles.hasPerformanceProfile
                ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                : [PowerProfile.PowerSaver, PowerProfile.Balanced]

            icon: PowerProfiles.profile === PowerProfile.PowerSaver ? "eco"
                : PowerProfiles.profile === PowerProfile.Performance ? "speed"
                : "balance"
            title: "Power mode"
            // Why Performance is slowed and which apps hold a mode (power-profiles-daemon).
            subtitle: PowerModes.note(PowerProfiles.profile === PowerProfile.PowerSaver ? "Power saver"
                                      : PowerProfiles.profile === PowerProfile.Performance ? "Performance"
                                      : "Balanced",
                                      PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "heat"
                                      : PowerProfiles.degradationReason === PerformanceDegradationReason.LapDetected ? "lap" : "",
                                      PowerProfiles.holds.map(h => DesktopEntries.heuristicLookup(h.applicationId)?.name || h.applicationId))
            active: PowerProfiles.profile !== PowerProfile.Balanced
            onClicked: {
                const next = (profiles.indexOf(PowerProfiles.profile) + 1) % profiles.length;
                PowerProfiles.profile = profiles[next];
            }
        }
    }

    Component {
        id: micToggle

        RoundToggle {
            icon: Audio.micMuted ? "mic_off" : "mic"
            title: Audio.micMuted ? "Microphone muted" : "Microphone on"
            active: !Audio.micMuted
            onClicked: Audio.toggleMicMute()
        }
    }

    Component {
        id: dndToggle

        RoundToggle {
            icon: Notifications.doNotDisturb ? "do_not_disturb_on" : "do_not_disturb_off"
            title: "Do Not Disturb"
            active: Notifications.doNotDisturb
            onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb
        }
    }

    Component {
        id: nightToggle

        RoundToggle {
            icon: NightLight.on ? "nightlight" : "light_mode"
            title: "Night light"
            active: NightLight.on
            onClicked: NightLight.toggle()
        }
    }

    Component {
        id: awakeToggle

        RoundToggle {
            icon: "coffee"
            title: "Keep awake"
            active: KeepAwake.on
            onClicked: KeepAwake.on = !KeepAwake.on
        }
    }

    Component {
        id: gameToggle

        RoundToggle {
            icon: "sports_esports"
            title: "Game mode"
            active: GameMode.on
            onClicked: GameMode.on = !GameMode.on
        }
    }

    // The today menu's timer: starts the length used last, and while it runs pauses and resumes
    // it (cancel it in the today menu). Its name says the time left.
    Component {
        id: timerToggle

        RoundToggle {
            icon: Countdown.paused ? "pause_circle" : "timer"
            title: !Countdown.active ? "Timer: start " + Countdown.lastMinutes + " min"
                 : Countdown.label + (Countdown.paused ? " left, paused" : " left: pause")
            active: Countdown.active && !Countdown.paused
            onClicked: !Countdown.active ? Countdown.start(Countdown.lastMinutes)
                     : Countdown.paused ? Countdown.resume() : Countdown.pause()
        }
    }

    // Focus mode: a 25-minute timer, pop-ups held back, the desktop widgets hidden.
    Component {
        id: focusToggle

        RoundToggle {
            icon: "self_improvement"
            title: Focus.on ? "Focus, " + Countdown.label + " left: end" : "Focus for " + Focus.minutes + " min"
            active: Focus.on
            onClicked: Focus.on ? Focus.stop() : Focus.start(Focus.minutes)
        }
    }

    // The Wi-Fi page's hotspot: shares a cable connection over Wi-Fi (it takes the Wi-Fi card off
    // its network, so only with a cable; the Wi-Fi page has its QR code).
    Component {
        id: hotspotToggle

        RoundToggle {
            icon: "wifi_tethering"
            title: NetworkExtras.hotspot ? "Hotspot on" : NetworkStatus.wired ? "Hotspot" : "Hotspot: needs a cable connection"
            active: NetworkExtras.hotspot
            onClicked: {
                if (NetworkExtras.hotspot || NetworkStatus.wired)
                    NetworkExtras.setHotspot(!NetworkExtras.hotspot);
            }
        }
    }

    // The next keyboard layout (Settings -> Keyboard and mouse sets them); the pop-up names it.
    Component {
        id: layoutToggle

        RoundToggle {
            icon: "keyboard"
            title: Keyboard.layout ? "Keyboard: " + Keyboard.layout : "Keyboard layout"
            active: Keyboard.layoutCount > 1
            onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
        }
    }

    // The screenshot tool's color picker: click anywhere, the #rrggbb is copied.
    Component {
        id: pickerToggle

        RoundToggle {
            icon: "colorize"
            title: "Color picker"
            onClicked: {
                root.openMenu("");
                Quickshell.execDetached(["sh", Quickshell.shellDir + "/screenshot/capture.sh", "color"]);
            }
        }
    }

    // LocalSend in the background, so devices nearby can send files here.
    Component {
        id: nearbyToggle

        RoundToggle {
            icon: "share"
            title: !NearbySharing.installed ? "Nearby sharing: needs LocalSend (ghost install phone)"
                 : NearbySharing.running ? "Nearby sharing on: visible to LocalSend" : "Nearby sharing"
            active: NearbySharing.running
            onClicked: {
                if (NearbySharing.installed)
                    NearbySharing.toggle();
            }

            Binding {
                target: NearbySharing
                property: "watching"
                value: root.visible
            }
        }
    }

    Component {
        id: airplaneToggle

        RoundToggle {
            icon: "flight"
            title: NetworkExtras.airplane ? "Airplane mode on" : "Airplane mode"
            active: NetworkExtras.airplane
            onClicked: NetworkExtras.setAirplane(!NetworkExtras.airplane)
        }
    }

    Component {
        id: darkToggle

        // Light and dark by hand (Settings' "At sunset" ends with it).
        RoundToggle {
            icon: ColorScheme.mode === "dark" ? "dark_mode" : "light_mode"
            title: "Dark mode"
            active: ColorScheme.mode === "dark"
            onClicked: Settings.values.colorScheme = ColorScheme.mode === "dark" ? "light" : "dark"
        }
    }

    Component {
        id: recordToggle

        // Stops a recording, or opens the screenshot tool on Record.
        RoundToggle {
            icon: "radio_button_checked"
            title: Recorder.recording ? "Stop recording" : "Record the screen"
            active: Recorder.recording
            onClicked: {
                if (Recorder.recording) {
                    Recorder.stop();
                } else {
                    root.openMenu("");
                    Quickshell.execDetached(["qs", "ipc", "call", "screenshot", "record"]);
                }
            }
        }
    }

    Component {
        id: screenshotToggle

        RoundToggle {
            icon: "screenshot_region"
            title: "Screenshot"
            onClicked: {
                root.openMenu("");
                Quickshell.execDetached(["qs", "ipc", "call", "screenshot", "region"]);
            }
        }
    }

    Component {
        id: wallpaperToggle

        RoundToggle {
            icon: "wallpaper"
            title: "Wallpaper"
            // The strip is an island menu: switch to it (setting Wallpaper.pickerOpen and then
            // closing this menu closed the strip again at once, so nothing showed).
            onClicked: root.openMenu("wallpaper")
        }
    }

    Column {
        id: mainPage

        x: root.page === "main" ? root.padding : -root.width
        width: root.width - root.padding * 2
        // Hidden once it has slid out, so Tab and the arrow keys skip its controls.
        visible: x > -width
        spacing: Theme.spacing.s

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }

        // The status icons and the battery, like the top of Android's quick settings (user's
        // choice, 2026-11-03: they left the closed island).
        Item {
            width: parent.width
            height: Theme.island.height
            visible: !root.editing

            StatusIcons {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.s
            }

            Row {
                visible: Battery.present
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

                BatteryPill {}

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Battery.level * 100) + "%" + (Battery.timeLabel ? " · " + Battery.timeLabel : "")
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                }
            }
        }

        // Edit mode's header: what it is, back to the defaults, and done.
        Item {
            width: parent.width
            height: Theme.island.height
            visible: root.editing

            Text {
                anchors.left: parent.left
                anchors.right: editButtons.left
                anchors.rightMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                text: "Drag to move, the corners remove or resize"
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
            }

            Row {
                id: editButtons
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.xs

                TextButton {
                    text: "Reset"
                    onClicked: {
                        Settings.values.quickTiles = QuickItems.defaultTiles.slice();
                        Settings.values.quickLarge = [];
                        Settings.values.quickToggles = QuickItems.defaultToggles.slice();
                    }
                }

                TextButton {
                    text: "Done"
                    filled: true
                    onClicked: root.editing = false
                }
            }
        }

        // The wide tiles, two to a row (a Flow: a Grid would widen a column for a whole-row tile).
        Flow {
            id: tileGrid
            width: parent.width
            spacing: Theme.spacing.s

            readonly property real tileWidth: (width - spacing) / 2
            // The tiles shown (no Bluetooth adapter: no tile), and the ones taking a whole row: the
            // ones you made large in edit mode, and a small one with nothing to pair with.
            readonly property var shownTiles: root.tileList.filter(id => id !== "bluetooth" || BluetoothStatus.adapter !== null)
            readonly property var largeTiles: QuickItems.shown(Settings.values.quickLarge, QuickItems.tiles, [])
            readonly property var fullRow: QuickItems.fullRow(shownTiles, largeTiles)

            function widthOf(id: string): real {
                return fullRow.includes(id) ? width : tileWidth;
            }

            Repeater {
                model: root.tileList

                QuickSlot {
                    required property string modelData
                    itemId: modelData
                    title: root.info[modelData].title
                    control: root.info[modelData].control
                    // No Bluetooth adapter: no tile, and no empty place for it in the grid.
                    visible: tileGrid.shownTiles.includes(modelData)
                    editing: root.editing
                    onRemoveRequested: Settings.values.quickTiles = QuickItems.removed(root.tileList, itemId)
                    onMoveRequested: to => Settings.values.quickTiles = OrderedList.moved(root.tileList, index, to)
                    // Large (the whole row) or small (half), like Android's tiles.
                    resizable: true
                    large: tileGrid.largeTiles.includes(itemId)
                    onResizeRequested: Settings.values.quickLarge = QuickItems.toggled(tileGrid.largeTiles, itemId)
                }
            }
        }

        // The simple on/off settings and shortcuts, as round buttons (Android 16's small tiles),
        // five to a row, or as many as fit when there are more (QuickItems.columns).
        Grid {
            id: toggleGrid

            // Above the sliders that follow, so a button's name (shown below it on hover) isn't
            // hidden behind the volume slider.
            z: 1
            width: parent.width
            columns: QuickItems.columns(root.toggleList.length, width, Theme.tile.round, Theme.spacing.l)
            rowSpacing: Theme.spacing.s
            // Spread evenly: the gaps share what the buttons leave.
            columnSpacing: (width - Theme.tile.round * columns) / (columns - 1)

            Repeater {
                model: root.toggleList

                QuickSlot {
                    required property string modelData
                    itemId: modelData
                    title: root.info[modelData].title
                    control: root.info[modelData].control
                    radius: Theme.radius.full
                    editing: root.editing
                    onRemoveRequested: Settings.values.quickToggles = QuickItems.removed(root.toggleList, itemId)
                    onMoveRequested: to => Settings.values.quickToggles = OrderedList.moved(root.toggleList, index, to)
                }
            }
        }

        // Edit mode: what isn't shown, to add.
        Column {
            width: parent.width
            visible: root.editing
            spacing: Theme.spacing.s

            SectionHeading {
                text: "Available"
            }

            Text {
                visible: available.count === 0
                text: "Everything is shown"
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
            }

            Flow {
                width: parent.width
                spacing: Theme.spacing.s

                Repeater {
                    id: available
                    model: QuickItems.available(root.tileList, QuickItems.tiles).map(id => ({ id: id, tile: true }))
                        .concat(QuickItems.available(root.toggleList, QuickItems.toggles).map(id => ({ id: id, tile: false })))

                    Rectangle {
                        id: chip

                        required property var modelData

                        function add(): void {
                            if (modelData.tile)
                                Settings.values.quickTiles = QuickItems.added(root.tileList, modelData.id);
                            else
                                Settings.values.quickToggles = QuickItems.added(root.toggleList, modelData.id);
                        }

                        width: chipRow.width + Theme.spacing.m * 2
                        height: Theme.island.height
                        radius: Theme.radius.full
                        color: Colors.tint
                        border.width: Theme.outline.normal
                        border.color: Colors.m3outlineVariant

                        Accessible.role: Accessible.Button
                        Accessible.name: "Add " + root.info[modelData.id].title
                        Accessible.onPressAction: add()
                        activeFocusOnTab: true
                        Keys.onReturnPressed: add()
                        Keys.onEnterPressed: add()
                        Keys.onSpacePressed: add()

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: Theme.spacing.xs

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: root.info[chip.modelData.id].icon
                                color: Colors.m3onSurface
                                font.pixelSize: Theme.icon.small
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.info[chip.modelData.id].title
                                color: Colors.m3onSurface
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.small
                            }

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "add"
                                color: Colors.m3primary
                                font.pixelSize: Theme.icon.small
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
                            onClicked: chip.add()
                        }
                    }
                }
            }
        }

        // The volume, and beside it where the sound goes: the button unfolds the outputs (and the
        // microphones, when there's more than one) under the slider, like a phone's output
        // picker; the Sound page has the same lists with the equalizer and the apps.
        LevelSlider {
            width: parent.width
            visible: !root.editing
            value: Audio.volume
            icon: Audio.icon
            label: "Volume"
            actionIcon: root.devicesOpen ? "expand_less" : Audio.deviceIcon(Audio.sink)
            actionLabel: root.devicesOpen ? "Hide sound outputs" : "Sound output: " + Audio.deviceName(Audio.sink)
            onMoved: value => Audio.setVolume(value)
            onActionClicked: root.devicesOpen = !root.devicesOpen
        }

        Column {
            width: parent.width
            visible: root.devicesOpen && !root.editing

            DeviceList {
                width: parent.width
                outputs: true
            }

            SectionHeading {
                visible: Audio.inputs.length > 1
                leftPadding: Theme.spacing.m
                topPadding: Theme.spacing.xs
                text: "Microphone"
            }

            DeviceList {
                width: parent.width
                visible: Audio.inputs.length > 1
                outputs: false
            }
        }

        LevelSlider {
            width: parent.width
            visible: !root.editing && Brightness.level >= 0
            value: Brightness.level
            icon: "brightness_medium"
            label: "Brightness"
            onMoved: value => Brightness.set(value)
        }

        // Things going on, each only while it is.
        StatusRow {
            width: parent.width
            visible: NetworkStatus.needsSignIn // a hotel's or café's Wi-Fi
            icon: "login"
            text: "This network needs you to sign in"
            buttonText: "Sign in"
            onClicked: {
                NetworkStatus.signIn();
                root.openMenu("");
            }
        }

        StatusRow {
            width: parent.width
            visible: Recorder.recording
            icon: "fiber_manual_record" // the red dot, like the island's
            iconColor: Colors.m3error
            iconSize: Theme.icon.small
            text: "Recording the screen · " + Recorder.time
            buttonText: "Stop"
            onClicked: Recorder.stop()
        }

        // Who's using the microphone, camera or screen right now, like Android's privacy
        // indicators.
        StatusRow {
            width: parent.width
            visible: Audio.recordingApps.length > 0
            icon: "mic"
            text: "Microphone in use by " + Audio.recordingApps.join(", ")
        }

        StatusRow {
            width: parent.width
            visible: Privacy.cameraInUse
            icon: "videocam"
            text: Privacy.cameraApps.length > 0 ? "Camera in use by " + Privacy.cameraApps.join(", ") : "Camera in use"
        }

        StatusRow {
            width: parent.width
            visible: Privacy.screenShared
            icon: "screen_share"
            text: "Your screen is being shared"
        }

        StatusRow {
            width: parent.width
            visible: Updates.count > 0
            icon: "download"
            iconColor: Colors.m3onSurface
            text: Updates.summary
            buttonText: "Update"
            onClicked: {
                Updates.update();
                root.openMenu("");
            }
        }

        // Edit, system, settings, wallpaper and power buttons (and background apps while there
        // are some).
        Item {
            width: parent.width
            visible: !root.editing
            implicitHeight: Theme.slider.height

            Row {
                id: bottomButtons
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.xs
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

                // The system tray's apps (user's choice, 2026-11-03: out of the island).
                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: SystemTray.items.values.length > 0
                    icon: "apps"
                    label: "Background apps"
                    onClicked: root.page = "apps"
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "edit"
                    label: "Edit quick settings"
                    onClicked: root.editing = true
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "monitoring"
                    label: "System"
                    onClicked: root.page = "system"
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "settings"
                    label: "Settings"
                    onClicked: {
                        LauncherState.showSettings("");
                        root.openMenu("");
                    }
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "wallpaper"
                    label: "Wallpaper"
                    onClicked: root.openMenu("wallpaper") // see the round wallpaper button
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "power_settings_new"
                    label: "Power menu"
                    onClicked: root.openMenu("power")
                }
            }
        }
    }

    WifiPage {
        id: wifiPage
        x: root.page === "wifi" ? root.padding : root.width
        width: root.width - root.padding * 2
        visible: x < root.width
        active: root.visible && root.page === "wifi"
        onBack: root.page = "main"

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    BluetoothPage {
        id: bluetoothPage
        x: root.page === "bluetooth" ? root.padding : root.width
        width: root.width - root.padding * 2
        visible: x < root.width
        active: root.visible && root.page === "bluetooth"
        onBack: root.page = "main"

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    SoundPage {
        id: soundPage
        x: root.page === "sound" ? root.padding : root.width
        width: root.width - root.padding * 2
        visible: x < root.width
        onBack: root.page = "main"

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    PhonePage {
        id: phonePage
        x: root.page === "phone" ? root.padding : root.width
        width: root.width - root.padding * 2
        visible: x < root.width
        onBack: root.page = "main"

        // Only ask KDE Connect while the tile or this page shows.
        Binding {
            target: Phone
            property: "active"
            value: root.visible && (root.page === "phone" || root.tileList.includes("phone"))
        }

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    ScreenPage { // the Display page (settings/ has a DisplayPage of its own)
        id: displayPage
        x: root.page === "display" ? root.padding : root.width
        width: root.width - root.padding * 2
        visible: x < root.width
        onBack: root.page = "main"
        onDone: root.openMenu("")

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    VpnPage {
        id: vpnPage
        x: root.page === "vpn" ? root.padding : root.width
        width: root.width - root.padding * 2
        visible: x < root.width
        onBack: root.page = "main"
        onDone: root.openMenu("")

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    Tray {
        id: appsPage
        x: root.page === "apps" ? root.padding : root.width
        width: root.width - root.padding * 2
        visible: x < root.width
        onBack: root.page = "main"
        onDone: root.openMenu("")

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    SystemPage {
        id: systemPage
        x: root.page === "system" ? root.padding : root.width
        width: root.width - root.padding * 2
        visible: x < root.width
        onBack: root.page = "main"

        // Only read the system while the page shows.
        Binding {
            target: SystemStats
            property: "active"
            value: root.visible && root.page === "system"
        }

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }
}
