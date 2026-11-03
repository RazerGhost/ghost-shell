import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Small status glyphs on the right of the closed island, like Android's status bar.
// Airplane mode, a VPN, Bluetooth, a timer, the microphone, camera or screen in use, waiting
// updates and mute only show up when they have something to say. MaterialIcon hides its glyph
// from screen readers (decorative elsewhere); here the glyph is the information, so each one
// says what it means (`Accessible.ignored: false`).
Row {
    id: root

    // Settings -> Appearance -> Status icons can hide all but the privacy ones (a recording,
    // the microphone, camera or screen in use), which always show.
    readonly property var hidden: Array.from(Settings.values.hiddenStatusIcons ?? [])

    function shows(key: string): bool {
        return !hidden.includes(key);
    }

    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.xs

    WifiIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("wifi")
        icon: NetworkStatus.icon
        font.pixelSize: Theme.icon.small
        Accessible.name: "Network: " + NetworkStatus.label
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("airplane") && NetworkExtras.airplane
        icon: "flight"
        font.pixelSize: Theme.icon.small
        Accessible.name: "Airplane mode"
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("vpn") && NetworkExtras.activeVpn !== null
        icon: "vpn_key"
        font.pixelSize: Theme.icon.small
        Accessible.name: "VPN: " + (NetworkExtras.activeVpn?.name ?? "")
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("bluetooth") && BluetoothStatus.connected.length > 0
        icon: "bluetooth_connected"
        font.pixelSize: Theme.icon.small
        Accessible.name: "Bluetooth: " + BluetoothStatus.label
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    // A screen recording is running: a red dot and the time (services/Recorder.qml).
    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: Recorder.recording
        spacing: Theme.spacing.xs

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.spacing.s
            height: width
            radius: width / 2
            color: Colors.m3error
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Recorder.time
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.features: { "tnum": 1 } // digits of equal width, so the time doesn't jitter
        }

        Accessible.role: Accessible.StaticText
        Accessible.name: "Recording the screen, " + Recorder.time
    }

    // The today menu's timer is running: the time left.
    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("timer") && Countdown.active
        spacing: Theme.spacing.xs

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: "timer"
            font.pixelSize: Theme.icon.small
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Countdown.label
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.features: { "tnum": 1 } // digits of equal width, so the time doesn't jitter
        }

        Accessible.role: Accessible.StaticText
        Accessible.name: "Timer, " + Countdown.label + " left"
    }

    // An app is recording from the microphone; red and crossed out while it's muted (talking
    // into a call that can't hear you).
    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Audio.recordingApps.length > 0
        icon: Audio.micMuted ? "mic_off" : "mic"
        color: Audio.micMuted ? Colors.m3error : Colors.m3primary
        font.pixelSize: Theme.icon.small
        Accessible.name: (Audio.micMuted ? "Microphone muted, but in use by " : "Microphone in use by ") + Audio.recordingApps.join(", ")
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Privacy.cameraInUse
        icon: "videocam"
        color: Colors.m3primary
        font.pixelSize: Theme.icon.small
        Accessible.name: "Camera in use"
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Privacy.screenShared
        icon: "screen_share"
        color: Colors.m3primary
        font.pixelSize: Theme.icon.small
        Accessible.name: "Your screen is being shared"
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("updates") && Updates.count > 0
        icon: "download"
        font.pixelSize: Theme.icon.small
        Accessible.name: Updates.summary
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shows("muted") && Audio.muted
        icon: "volume_off"
        font.pixelSize: Theme.icon.small
        Accessible.name: "Sound muted"
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }

    BatteryPill {
        visible: root.shows("battery") && Battery.present
    }
}
