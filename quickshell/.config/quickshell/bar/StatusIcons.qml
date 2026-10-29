import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Small status glyphs on the right of the closed island, like Android's status bar.
// Airplane mode, a VPN, Bluetooth, a timer, the microphone, camera or screen in use, waiting
// updates and mute only show up when they have something to say.
Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.xs

    WifiIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon: NetworkStatus.icon
        font.pixelSize: Theme.icon.small
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: NetworkExtras.airplane
        icon: "flight"
        font.pixelSize: Theme.icon.small
        Accessible.name: "Airplane mode"
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: NetworkExtras.activeVpn !== null
        icon: "vpn_key"
        font.pixelSize: Theme.icon.small
        Accessible.name: "VPN: " + (NetworkExtras.activeVpn?.name ?? "")
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: BluetoothStatus.connected.length > 0
        icon: "bluetooth_connected"
        font.pixelSize: Theme.icon.small
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
        visible: Countdown.active
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

    // An app is recording from the microphone.
    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Audio.recordingApps.length > 0
        icon: "mic"
        color: Colors.m3primary
        font.pixelSize: Theme.icon.small
        Accessible.name: "Microphone in use by " + Audio.recordingApps.join(", ")
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Privacy.cameraInUse
        icon: "videocam"
        color: Colors.m3primary
        font.pixelSize: Theme.icon.small
        Accessible.name: "Camera in use"
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Privacy.screenShared
        icon: "screen_share"
        color: Colors.m3primary
        font.pixelSize: Theme.icon.small
        Accessible.name: "Your screen is being shared"
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Updates.count > 0
        icon: "download"
        font.pixelSize: Theme.icon.small
        Accessible.name: Updates.summary
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Audio.muted
        icon: "volume_off"
        font.pixelSize: Theme.icon.small
    }

    BatteryPill {
        visible: Battery.present
    }
}
