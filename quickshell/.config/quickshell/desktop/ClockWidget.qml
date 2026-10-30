import QtQuick
import Quickshell
import qs.services
import qs.theme

// The clock widget (medium): the weekday in the accent, the time large, the date under it.
WidgetSurface {
    medium: true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: -Theme.spacing.xs

        Text {
            // English names even with Dutch regional formats, like the calendar.
            text: Qt.locale(Qt.uiLanguage).toString(clock.date, "dddd").toUpperCase()
            color: Colors.m3primary
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Text {
            // Shrinks to fit a long 12-hour time ("12:59 PM") rather than spill out.
            width: parent.width
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.font.title
            text: Qt.formatTime(clock.date, Settings.values.clock24Hour ? "HH:mm" : "h:mm AP")
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.desktop.clock
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Text {
            text: Qt.locale(Qt.uiLanguage).toString(clock.date, "d MMMM")
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
        }
    }
}
