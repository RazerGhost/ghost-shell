import QtQuick
import Quickshell
import qs.services
import qs.theme

// The time, e.g. "14:32"; with Settings' clockDate the day too ("Thu 29  14:32"), with
// clockSeconds the seconds. The full date is in the calendar menu (click the time).
Text {
    anchors.verticalCenter: parent.verticalCenter
    readonly property string time: Settings.values.clock24Hour
        ? (Settings.values.clockSeconds ? "HH:mm:ss" : "HH:mm")
        : (Settings.values.clockSeconds ? "h:mm:ss AP" : "h:mm AP")
    // English day names with Dutch regional formats (see the calendar locale decision).
    text: (Settings.values.clockDate ? clock.date.toLocaleDateString(Qt.locale(Qt.uiLanguage), "ddd d") + "  " : "")
          + Qt.formatDateTime(clock.date, time)
    color: Colors.m3onSurface
    font.family: Theme.font.sans
    font.pixelSize: Theme.font.normal
    font.weight: Font.DemiBold
    font.features: { "tnum": 1 } // tabular digits, so the island doesn't twitch as they change

    // Ticks once a minute, or every second while it shows seconds.
    SystemClock {
        id: clock
        precision: Settings.values.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
