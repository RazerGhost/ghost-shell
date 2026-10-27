import QtQuick
import Quickshell
import qs.theme

// Time and date, e.g. "14:32  Tue 27 Oct".
Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.s

    // Ticks once a minute instead of every second.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Colors.onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        font.weight: Font.DemiBold
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        color: Colors.onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
