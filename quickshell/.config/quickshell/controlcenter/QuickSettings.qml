import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.settings
import qs.theme
import qs.widgets
import "QuickItems.js" as QuickItems
import "../widgets/OrderedList.js" as OrderedList

// The quick settings menu: tiles, volume and brightness sliders and the battery.
// The Wi-Fi, Bluetooth and Sound tiles slide in a page of their own, like Android.
Item {
    id: root

    property string page: "main" // "main", "wifi", "bluetooth", "sound" or "system"

    // A button here opens another island menu ("power"), or closes the island ("").
    signal openMenu(string menu)
    readonly property int padding: Theme.spacing.l

    // Your tiles and round buttons, in your order (Settings' quickTiles and quickToggles), and
    // edit mode, where they're added, removed and moved on the panel itself, like Android.
    property bool editing: false
    readonly property var tileList: QuickItems.shown(Settings.values.quickTiles, QuickItems.tiles, QuickItems.defaultTiles)
    readonly property var toggleList: QuickItems.shown(Settings.values.quickToggles, QuickItems.toggles, QuickItems.defaultToggles)
    // Each one's name, icon and control (a component below), for its slot, edit mode's labels and
    // its "Available" chips.
    readonly property var info: ({
        wifi: { icon: "wifi", title: "Wi-Fi", control: wifiTile },
        bluetooth: { icon: "bluetooth", title: "Bluetooth", control: bluetoothTile },
        sound: { icon: "volume_up", title: "Sound", control: soundTile },
        power: { icon: "balance", title: "Power mode", control: powerTile },
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
        timer: { icon: "timer", title: "Timer", control: timerToggle }
    })

    // The island grows and shrinks to fit the current page.
    implicitHeight: (page === "wifi" ? wifiPage : page === "bluetooth" ? bluetoothPage
                     : page === "sound" ? soundPage : page === "system" ? systemPage : mainPage).implicitHeight
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
            width: tileGrid.tileWidth
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
            width: tileGrid.tileWidth
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
            width: tileGrid.tileWidth
            icon: Audio.icon
            title: "Sound"
            subtitle: Audio.sink ? Audio.deviceName(Audio.sink) : "No output"
            active: !Audio.muted
            hasPage: true
            onClicked: root.page = "sound"
        }
    }

    Component {
        id: powerTile

        // power-profiles-daemon. Cycles power saver -> balanced -> performance.
        Tile {
            width: tileGrid.tileWidth

            // Some machines have no performance profile; skip it when cycling there.
            readonly property list<int> profiles: PowerProfiles.hasPerformanceProfile
                ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                : [PowerProfile.PowerSaver, PowerProfile.Balanced]

            icon: PowerProfiles.profile === PowerProfile.PowerSaver ? "eco"
                : PowerProfiles.profile === PowerProfile.Performance ? "speed"
                : "balance"
            title: "Power mode"
            subtitle: PowerProfiles.profile === PowerProfile.PowerSaver ? "Power saver"
                    : PowerProfiles.profile === PowerProfile.Performance ? "Performance"
                    : "Balanced"
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
            onClicked: {
                Wallpaper.pickerOpen = true;
                root.openMenu("");
            }
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

        // Edit mode's header: what it is, back to the defaults, and done.
        Item {
            width: parent.width
            height: Theme.island.height
            visible: root.editing

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Drag to move, − to remove"
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.xs

                TextButton {
                    text: "Reset"
                    onClicked: {
                        Settings.values.quickTiles = QuickItems.defaultTiles.slice();
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

        // The wide tiles, two to a row.
        Grid {
            id: tileGrid
            width: parent.width
            columns: 2
            spacing: Theme.spacing.s

            readonly property real tileWidth: (width - spacing) / 2

            Repeater {
                model: root.tileList

                QuickSlot {
                    required property string modelData
                    itemId: modelData
                    title: root.info[modelData].title
                    control: root.info[modelData].control
                    // No Bluetooth adapter: no tile, and no empty place for it in the grid.
                    visible: modelData !== "bluetooth" || BluetoothStatus.adapter !== null
                    editing: root.editing
                    onRemoveRequested: Settings.values.quickTiles = QuickItems.removed(root.tileList, itemId)
                    onMoveRequested: to => Settings.values.quickTiles = OrderedList.moved(root.tileList, index, to)
                }
            }
        }

        // The simple on/off settings and shortcuts, as round buttons (Android 16's small tiles),
        // five to a row.
        Grid {
            id: toggleGrid

            // Above the sliders that follow, so a button's name (shown below it on hover) isn't
            // hidden behind the volume slider.
            z: 1
            width: parent.width
            columns: 5
            rowSpacing: Theme.spacing.s
            // Spread evenly: the gaps share what the buttons leave.
            columnSpacing: (width - Theme.tile.round * 5) / 4

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

        LevelSlider {
            width: parent.width
            visible: !root.editing
            value: Audio.volume
            icon: Audio.icon
            label: "Volume"
            onMoved: value => Audio.setVolume(value)
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

        // Battery on the left; edit, system, settings, wallpaper and power buttons on the right.
        Item {
            width: parent.width
            visible: !root.editing
            implicitHeight: Theme.slider.height

            Row {
                visible: Battery.present
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

                MaterialIcon {
                    id: batteryIcon
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Battery.icon
                    color: Battery.low ? Colors.m3error : Colors.m3onSurface
                }

                // Up to the buttons, then "…".
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, bottomButtons.x - Theme.spacing.s * 3 - batteryIcon.width)
                    elide: Text.ElideRight
                    text: Math.round(Battery.level * 100) + "%" + (Battery.timeLabel ? " · " + Battery.timeLabel : "")
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }

            Row {
                id: bottomButtons
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.xs
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

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
                        SettingsWindow.open = true;
                        root.openMenu("");
                    }
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "wallpaper"
                    label: "Wallpaper"
                    onClicked: {
                        Wallpaper.pickerOpen = true;
                        root.openMenu("");
                    }
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
