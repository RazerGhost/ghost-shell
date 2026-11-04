import QtQuick
import qs.services
import qs.theme
import qs.widgets

// What needs attention, beside the time in the closed island (user's choice, 2026-11-03: the
// other status icons are in quick settings, controlcenter/StatusIcons.qml): a screen recording with its time,
// the timer's time left, the microphone, camera or screen in use (like Android's privacy dots),
// and a low battery. Each shows only while it's going on. The glyph is the information, so each
// says what it means to screen readers (StatusGlyph); `summary` is all
// of them, for the island's button, which they sit inside. A click on one goes where it leads
// (IslandTap): the event and the timer to the today menu, the recording stops, the rest open
// quick settings, whose status lines name the apps.
Row {
    id: root

    // The today menu, on one of its parts ("" or "timer"), and quick settings.
    signal todayRequested(string part)
    signal settingsRequested()

    // Focus mode's timer always shows: it's the only sign focus mode is on.
    readonly property bool timerShown: Countdown.active && (Focus.on || !Array.from(Settings.values.hiddenStatusIcons ?? []).includes("timer"))
    readonly property bool lowBattery: Battery.present && Battery.low

    readonly property string recordingText: Recorder.recording ? "Recording the screen, " + Recorder.time : ""
    readonly property string timerText: timerShown ? (Focus.on ? "Focus, " : Focus.onBreak ? "Break, " : "Timer, ") + Countdown.label + " left" : ""
    readonly property string micText: Audio.recordingApps.length === 0 ? ""
        : (Audio.micMuted ? "Microphone muted, but in use by " : "Microphone in use by ") + Audio.recordingApps.join(", ")
    readonly property string cameraText: Privacy.cameraInUse ? "Camera in use" : ""
    readonly property string screenText: Privacy.screenShared ? "Your screen is being shared" : ""
    readonly property string batteryText: lowBattery ? "Battery low, " + Math.round(Battery.level * 100) + "%" : ""
    readonly property string soonLabel: Agenda.soon === null ? "" : "in " + Agenda.soon.minutes + " min"
    readonly property string soonText: Agenda.soon === null ? "" : Agenda.soon.title + " " + soonLabel
    readonly property string summary: [soonText, recordingText, timerText, micText, cameraText, screenText, batteryText]
        .filter(text => text !== "").join(". ")

    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.xs

    // A calendar event starts within 15 minutes: when, beside an event icon (its title is in the
    // today menu: the island is seen by anyone looking at the screen).
    Item {
        anchors.verticalCenter: parent.verticalCenter
        visible: Agenda.soon !== null
        implicitWidth: soonRow.implicitWidth
        implicitHeight: soonRow.implicitHeight
        Accessible.role: Accessible.StaticText
        Accessible.name: "Up next: " + root.soonText

        Row {
            id: soonRow
            spacing: Theme.spacing.xs

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "event_upcoming"
                color: Colors.m3primary
                font.pixelSize: Theme.icon.small
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.soonLabel
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                font.features: { "tnum": 1 }
            }
        }

        IslandTap {
            label: "See the event"
            onTapped: root.todayRequested("")
        }
    }

    // A screen recording is running: a red dot and the time (services/Recorder.qml).
    Item {
        anchors.verticalCenter: parent.verticalCenter
        visible: Recorder.recording
        implicitWidth: recordingRow.implicitWidth
        implicitHeight: recordingRow.implicitHeight
        Accessible.role: Accessible.StaticText
        Accessible.name: root.recordingText

        Row {
            id: recordingRow
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
        }

        IslandTap {
            label: "Stop the recording"
            onTapped: Recorder.stop()
        }
    }

    // The today menu's timer is running: the time left.
    Item {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.timerShown
        implicitWidth: timerRow.implicitWidth
        implicitHeight: timerRow.implicitHeight
        Accessible.role: Accessible.StaticText
        Accessible.name: root.timerText

        Row {
            id: timerRow
            spacing: Theme.spacing.xs

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: Focus.on ? "self_improvement" : Focus.onBreak ? "coffee" : "timer"
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
        }

        IslandTap {
            label: "Open the timer"
            onTapped: root.todayRequested("timer")
        }
    }

    // An app is recording from the microphone; red and crossed out while it's muted (talking
    // into a call that can't hear you).
    StatusGlyph {
        visible: Audio.recordingApps.length > 0
        icon: Audio.micMuted ? "mic_off" : "mic"
        color: Audio.micMuted ? Colors.m3error : Colors.m3primary
        label: root.micText

        IslandTap {
            label: "See who's using the microphone"
            onTapped: root.settingsRequested()
        }
    }

    StatusGlyph {
        visible: Privacy.cameraInUse
        icon: "videocam"
        color: Colors.m3primary
        label: root.cameraText

        IslandTap {
            label: "See who's using the camera"
            onTapped: root.settingsRequested()
        }
    }

    StatusGlyph {
        visible: Privacy.screenShared
        icon: "screen_share"
        color: Colors.m3primary
        label: root.screenText

        IslandTap {
            label: "See the screen sharing"
            onTapped: root.settingsRequested()
        }
    }

    StatusGlyph {
        visible: root.lowBattery
        icon: Battery.icon
        color: Colors.m3error
        label: root.batteryText

        IslandTap {
            label: "Open quick settings"
            onTapped: root.settingsRequested()
        }
    }
}
