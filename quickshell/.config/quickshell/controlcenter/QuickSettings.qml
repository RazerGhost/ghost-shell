import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.settings
import qs.theme
import qs.widgets

// The quick settings menu: tiles, volume and brightness sliders and the battery.
// The Wi-Fi, Bluetooth and Sound tiles slide in a page of their own, like Android.
Item {
    id: root

    property string page: "main" // "main", "wifi", "bluetooth", "sound" or "system"

    // A button here opens another island menu ("power"), or closes the island ("").
    signal openMenu(string menu)
    readonly property int padding: Theme.spacing.l

    // The island grows and shrinks to fit the current page.
    implicitHeight: (page === "wifi" ? wifiPage : page === "bluetooth" ? bluetoothPage
                     : page === "sound" ? soundPage : page === "system" ? systemPage : mainPage).implicitHeight
                    + padding
    clip: true // pages slide in from the side

    // Start on the main page next time.
    onVisibleChanged: {
        if (!visible)
            page = "main";
    }

    Column {
        id: mainPage

        x: root.page === "main" ? root.padding : -root.width
        width: root.width - root.padding * 2
        spacing: Theme.spacing.s

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }

        Grid {
            width: parent.width
            columns: 2
            spacing: Theme.spacing.s

            readonly property real tileWidth: (width - spacing) / 2

            Tile {
                width: parent.tileWidth
                icon: NetworkStatus.icon
                title: "Wi-Fi"
                subtitle: NetworkStatus.label
                active: NetworkStatus.wired || NetworkStatus.wifiNetwork !== null
                hasPage: true
                onClicked: root.page = "wifi"
            }

            Tile {
                width: parent.tileWidth
                visible: BluetoothStatus.adapter !== null
                icon: BluetoothStatus.icon
                title: "Bluetooth"
                subtitle: BluetoothStatus.label
                active: BluetoothStatus.enabled
                hasPage: true
                onClicked: root.page = "bluetooth"
            }

            Tile {
                width: parent.tileWidth
                icon: Audio.icon
                title: "Sound"
                subtitle: Audio.sink ? Audio.deviceName(Audio.sink) : "No output"
                active: !Audio.muted
                hasPage: true
                onClicked: root.page = "sound"
            }

            // power-profiles-daemon. Cycles power saver -> balanced -> performance.
            Tile {
                width: parent.tileWidth

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

        // The simple on/off settings, as round buttons (Android 16's small tiles).
        Row {
            id: toggles

            // Above the sliders that follow, so a button's name (shown below it on hover) isn't
            // hidden behind the volume slider.
            z: 1
            width: parent.width
            // Spread evenly: the gaps share what the buttons leave.
            spacing: (width - Theme.tile.round * 5) / 4

            RoundToggle {
                icon: Audio.micMuted ? "mic_off" : "mic"
                title: Audio.micMuted ? "Microphone muted" : "Microphone on"
                active: !Audio.micMuted
                onClicked: Audio.toggleMicMute()
            }

            RoundToggle {
                icon: Notifications.doNotDisturb ? "do_not_disturb_on" : "do_not_disturb_off"
                title: "Do Not Disturb"
                active: Notifications.doNotDisturb
                onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb
            }

            RoundToggle {
                icon: NightLight.on ? "nightlight" : "light_mode"
                title: "Night light"
                active: NightLight.on
                onClicked: NightLight.toggle()
            }

            RoundToggle {
                icon: "coffee"
                title: "Keep awake"
                active: KeepAwake.on
                onClicked: KeepAwake.on = !KeepAwake.on
            }

            RoundToggle {
                icon: "sports_esports"
                title: "Game mode"
                active: GameMode.on
                onClicked: GameMode.on = !GameMode.on
            }
        }

        LevelSlider {
            width: parent.width
            value: Audio.volume
            icon: Audio.icon
            label: "Volume"
            onMoved: value => Audio.setVolume(value)
        }

        LevelSlider {
            width: parent.width
            visible: Brightness.level >= 0
            value: Brightness.level
            icon: "brightness_medium"
            label: "Brightness"
            onMoved: value => Brightness.set(value)
        }

        // The network wants you to sign in (a hotel's or café's Wi-Fi).
        Item {
            width: parent.width
            implicitHeight: Theme.slider.height
            visible: NetworkStatus.needsSignIn

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "login"
                    color: Colors.m3primary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "This network needs you to sign in"
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }

            TextButton {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.xs
                anchors.verticalCenter: parent.verticalCenter
                text: "Sign in"
                onClicked: {
                    NetworkStatus.signIn();
                    root.openMenu("");
                }
            }
        }

        // A screen recording: its time and a Stop button.
        Item {
            width: parent.width
            implicitHeight: Theme.slider.height
            visible: Recorder.recording

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.spacing.s
                    height: width
                    radius: width / 2
                    color: Colors.m3error
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Recording the screen · " + Recorder.time
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }

            TextButton {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.xs
                anchors.verticalCenter: parent.verticalCenter
                text: "Stop"
                onClicked: Recorder.stop()
            }
        }

        // Who's using the microphone, camera or screen right now, like Android's privacy
        // indicators.
        InUseRow {
            visible: Audio.recordingApps.length > 0
            icon: "mic"
            text: "Microphone in use by " + Audio.recordingApps.join(", ")
        }

        InUseRow {
            visible: Privacy.cameraInUse
            icon: "videocam"
            text: Privacy.cameraApps.length > 0 ? "Camera in use by " + Privacy.cameraApps.join(", ") : "Camera in use"
        }

        InUseRow {
            visible: Privacy.screenShared
            icon: "screen_share"
            text: "Your screen is being shared"
        }

        // Waiting updates (services/Updates.qml), only when there are some.
        Item {
            width: parent.width
            implicitHeight: Theme.slider.height
            visible: Updates.count > 0

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "download"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Updates.summary
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }

            TextButton {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.xs
                anchors.verticalCenter: parent.verticalCenter
                text: "Update"
                onClicked: {
                    Updates.update();
                    root.openMenu("");
                }
            }
        }

        // Battery on the left; settings, wallpaper and power buttons on the right.
        Item {
            width: parent.width
            implicitHeight: Theme.slider.height

            Row {
                visible: Battery.present
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Battery.icon
                    color: Battery.low ? Colors.m3error : Colors.m3onSurface
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Battery.level * 100) + "%" + (Battery.timeLabel ? " · " + Battery.timeLabel : "")
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.xs
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing.s

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
        onBack: root.page = "main"

        Behavior on x {
            NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
        }
    }

    SystemPage {
        id: systemPage
        x: root.page === "system" ? root.padding : root.width
        width: root.width - root.padding * 2
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
