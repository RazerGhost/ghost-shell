import QtQuick
import qs.services
import qs.theme
import qs.widgets

// What needs attention, beside the time in the closed island (user's choice, 2026-11-03: the
// other status icons are in quick settings, controlcenter/StatusIcons.qml): a screen recording with its time,
// the timer's time left, the microphone, camera or screen in use (like Android's privacy dots),
// and a low battery. Each shows only while it's going on. The glyph is the information, so each
// says what it means to screen readers (MaterialIcon hides its glyph by default).
Row {
    id: root

    readonly property bool timerShown: Countdown.active && !Array.from(Settings.values.hiddenStatusIcons ?? []).includes("timer")
    readonly property bool lowBattery: Battery.present && Battery.low
    // Something shows (the island keeps a gap before it only then).
    readonly property bool any: Recorder.recording || timerShown || Audio.recordingApps.length > 0
                                || Privacy.cameraInUse || Privacy.screenShared || lowBattery

    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.xs

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
        visible: root.timerShown
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
        visible: root.lowBattery
        icon: Battery.icon
        color: Colors.m3error
        font.pixelSize: Theme.icon.small
        Accessible.name: "Battery low, " + Math.round(Battery.level * 100) + "%"
        Accessible.ignored: false
        Accessible.role: Accessible.StaticText
    }
}
