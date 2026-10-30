import QtQuick
import Quickshell
import qs.services
import qs.theme

// The calendar widget (medium), like iOS's: today's date on the left (the month in the accent,
// the day large), the next events on the right (services/Agenda.qml, from the calendars
// `ghost calendar add` subscribed to). Clicking it opens the today menu.
WidgetSurface {
    id: widget

    medium: true

    readonly property var events: Agenda.upcoming.slice(0, 3)

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "island", "toggle", "today"])
    }

    Column {
        id: date
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.desktop.size - Theme.desktop.padding * 2
        spacing: -Theme.spacing.xs

        Text {
            // English names even with Dutch regional formats, like the calendar.
            text: Qt.locale(Qt.uiLanguage).toString(clock.date, "MMMM").toUpperCase()
            color: Colors.m3primary
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Text {
            text: clock.date.getDate()
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.desktop.clock
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Text {
            text: Qt.locale(Qt.uiLanguage).toString(clock.date, "dddd")
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
        }
    }

    // The next events, each its title and when; or why there are none.
    Column {
        anchors.left: date.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.desktop.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.s

        Repeater {
            model: widget.events

            Row {
                id: event

                required property var modelData

                width: parent.width
                spacing: Theme.spacing.s

                // A bar in the accent beside each, like a calendar's event.
                Rectangle {
                    width: 3
                    height: parent.height
                    radius: 1.5
                    color: Colors.m3primary
                }

                Column {
                    width: parent.width - Theme.spacing.s - 3

                    Text {
                        width: parent.width
                        text: event.modelData.title
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.normal
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: Agenda.when(event.modelData)
                        color: Colors.m3onSurfaceVariant
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.small
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: widget.events.length === 0
            text: Agenda.enabled ? "Nothing coming up" : "No calendar yet"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.Medium
            wrapMode: Text.Wrap
        }

        Text {
            width: parent.width
            visible: widget.events.length === 0 && !Agenda.enabled
            text: "Add one in a terminal:"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }

        Text {
            width: parent.width
            visible: widget.events.length === 0 && !Agenda.enabled
            text: "ghost calendar add"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.mono
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }
}
