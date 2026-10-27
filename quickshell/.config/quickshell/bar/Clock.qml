import QtQuick
import Quickshell
import qs.theme

// The time, e.g. "14:32". The date is in the calendar menu (click the time).
Text {
    anchors.verticalCenter: parent.verticalCenter
    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: Colors.m3onSurface
    font.family: Theme.font.sans
    font.pixelSize: Theme.font.normal
    font.weight: Font.DemiBold
    font.features: { "tnum": 1 } // tabular digits, so the island doesn't twitch every minute

    // Ticks once a minute instead of every second.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
