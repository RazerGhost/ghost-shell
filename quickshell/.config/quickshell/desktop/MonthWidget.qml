import QtQuick
import QtQuick.Controls
import Quickshell
import qs.services
import qs.theme

// The month widget (large), a calendar of its own: this month's days with today in the accent
// and a dot under days with an event, and the next events under it (services/Agenda.qml, from
// the calendars `ghost calendar add` subscribed to). Clicking it opens the today menu. On the
// lock screen (`hidesTitles`) each event reads "Event": when, not what.
WidgetSurface {
    id: widget

    // Keyboard mode: Enter opens the today menu, like a click.
    function key(event: var): bool {
        if (!enabled || !(event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space))
            return false;
        Quickshell.execDetached(["qs", "ipc", "call", "island", "toggle", "today"]);
        return true;
    }

    large: true
    property bool hidesTitles: false

    // Rows of events that fit under the grid.
    readonly property var events: Agenda.upcoming.slice(0, 3)

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: openToday()

        function openToday(): void {
            Quickshell.execDetached(["qs", "ipc", "call", "island", "toggle", "today"]);
        }

        // A button on the desktop; on the lock screen (disabled) plain text with no action.
        Accessible.role: enabled ? Accessible.Button : Accessible.StaticText
        Accessible.name: Qt.locale(Qt.uiLanguage).toString(clock.date, "dddd d MMMM")
                         + (enabled ? ": open the today menu" : "")
        Accessible.onPressAction: openToday()
    }

    Column {
        id: month
        width: parent.width
        spacing: Theme.spacing.xs

        Item {
            width: parent.width
            height: name.height

            Text {
                id: name
                // English names even with Dutch regional formats, like the island's date.
                text: Qt.locale(Qt.uiLanguage).toString(clock.date, "MMMM").toUpperCase()
                color: Colors.m3primary
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Text {
                anchors.right: parent.right
                text: clock.date.getFullYear()
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
            }
        }

        // DayOfWeekRow and MonthGrid come with Qt Quick Controls; the first
        // day of the week follows the UI language (en_GB: Monday).
        DayOfWeekRow {
            id: weekdays
            width: parent.width
            locale: grid.locale

            delegate: Text {
                required property string shortName
                text: shortName
                horizontalAlignment: Text.AlignHCenter
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
            }
        }

        MonthGrid {
            id: grid

            // Six weeks fill what's left above the events.
            readonly property real cell: (widget.height - Theme.desktop.padding * 2 - name.height - weekdays.height
                                          - agenda.height - month.spacing * 3) / 6

            width: parent.width
            month: clock.date.getMonth()
            year: clock.date.getFullYear()
            locale: Qt.locale(Qt.uiLanguage)
            // MonthGrid always lays out 6 weeks and doesn't size itself.
            implicitHeight: cell * 6
            spacing: 0

            delegate: Item {
                id: cell

                required property int day
                required property int month
                required property int year
                required property bool today
                // Agenda's events cover this month and the coming week.
                readonly property bool hasEvent: Agenda.days[`${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`] === true

                implicitHeight: grid.cell

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(grid.cell, Theme.font.normal * 2.2)
                    height: width
                    radius: width / 2
                    color: Colors.m3primary
                    visible: cell.today
                }

                Text {
                    anchors.centerIn: parent
                    // Only this month's days: the others would crowd the small card.
                    visible: cell.month === grid.month
                    text: cell.day
                    color: cell.today ? Colors.m3onPrimary : Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    font.weight: cell.today ? Font.DemiBold : Font.Normal
                    font.features: { "tnum": 1 }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: Theme.spacing.xs
                    height: width
                    radius: width / 2
                    color: Colors.m3primary
                    visible: cell.hasEvent && cell.month === grid.month && !cell.today
                }
            }
        }
    }

    // The next events: a bar in the accent, the title and when on one line.
    Column {
        id: agenda
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: Theme.spacing.xs

        Repeater {
            model: widget.events

            Row {
                id: event

                required property var modelData

                width: parent.width
                spacing: Theme.spacing.s

                Rectangle {
                    width: Theme.desktop.eventBar
                    height: parent.height
                    radius: width / 2
                    color: Colors.m3primary
                }

                Text {
                    id: title
                    width: parent.width - Theme.desktop.eventBar - Theme.spacing.s * 2 - when.width
                    text: widget.hidesTitles ? "Event" : event.modelData.title
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    id: when
                    anchors.baseline: title.baseline
                    text: Agenda.when(event.modelData)
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                }
            }
        }

        Text {
            visible: widget.events.length === 0
            text: Agenda.enabled || widget.hidesTitles ? "Nothing coming up" : "No calendar yet: ghost calendar add"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }
    }
}
