import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The timer widget (small), the today menu's timer (services/Countdown.qml): while it runs, a
// ring that empties with the time left around the time, with pause or resume and cancel; else
// four lengths to start. On the lock screen (disabled there) no buttons: it says whether one runs.
WidgetSurface {
    id: widget

    Text {
        visible: !Countdown.active
        text: "TIMER"
        color: Colors.m3primary
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }

    // Not running: the lengths, two by two; on the lock screen, that none runs.
    Text {
        visible: !Countdown.active && !widget.enabled
        anchors.bottom: parent.bottom
        text: "Not running"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }

    Grid {
        visible: !Countdown.active && widget.enabled
        anchors.bottom: parent.bottom
        width: parent.width
        columns: 2
        spacing: Theme.spacing.s

        Repeater {
            model: Countdown.lengths

            TextButton {
                required property int modelData
                width: (parent.width - Theme.spacing.s) / 2
                // Tinted, so they read as buttons on the glass (bare text looked unfinished).
                color: Colors.tint
                text: modelData + " min"
                onClicked: Countdown.start(modelData)
            }
        }
    }

    // Running: the ring with the time in it, and its buttons under it.
    ProgressRing {
        id: ring
        visible: Countdown.active
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.desktop.ring
        height: width
        value: Countdown.progress
        color: Countdown.paused ? Colors.m3onSurfaceVariant : Colors.m3primary

        Text {
            anchors.centerIn: parent
            width: parent.width - Theme.desktop.ringWidth * 3
            horizontalAlignment: Text.AlignHCenter
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.font.small
            text: Countdown.label
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }

    Row {
        visible: Countdown.active && widget.enabled
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacing.s

        IconButton {
            icon: Countdown.paused ? "play_arrow" : "pause"
            label: Countdown.paused ? "Resume the timer" : "Pause the timer"
            onClicked: Countdown.paused ? Countdown.resume() : Countdown.pause()
        }

        IconButton {
            icon: "close"
            label: "Cancel the timer"
            onClicked: Countdown.cancel()
        }
    }

    Accessible.role: Accessible.Grouping
    Accessible.name: Countdown.active ? "Timer, " + Countdown.label + " left" + (Countdown.paused ? ", paused" : "") : "Timer"
}
