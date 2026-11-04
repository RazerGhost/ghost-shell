import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "Greeting.js" as Greeting

// What the island says right after the lock screen lets you in (bar/Island.qml's welcome):
// "Good morning, Name" after the login, "Welcome back, Name" after a later unlock, and what's
// waiting at a glance: the weather, notifications, the next event, open tasks, a running timer.
// A click opens the today menu.
MouseArea {
    id: root

    // The login's unlock, not a later one.
    property bool first: false

    signal activated()

    readonly property var items: [
        Weather.current ? { icon: Weather.current.icon, text: Weather.current.temperature + "° " + Weather.current.label } : null,
        Notifications.history.length > 0 ? { icon: "notifications", text: Greeting.count(Notifications.history.length, "notification", "notifications") } : null,
        Agenda.upcoming.length > 0 ? { icon: "event", text: Agenda.upcoming[0].title + " · " + Agenda.when(Agenda.upcoming[0]) } : null,
        Planner.open > 0 ? { icon: "checklist", text: Greeting.count(Planner.open, "task", "tasks") } : null,
        Countdown.active ? { icon: "timer", text: Countdown.label + " left" } : null
    ].filter(i => i !== null)

    implicitHeight: body.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: activated()

    Accessible.role: Accessible.AlertMessage
    Accessible.name: title.text + ". " + items.map(i => i.text).join(", ")
    Accessible.onPressAction: activated()

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    Column {
        id: body
        width: parent.width
        topPadding: Theme.spacing.xs
        bottomPadding: Theme.spacing.m
        spacing: Theme.spacing.m

        Text {
            id: title
            x: Theme.spacing.l
            width: parent.width - Theme.spacing.l * 2
            text: Greeting.greeting(clock.date.getHours(), Session.userName, root.first)
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.title
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        // What's waiting, as chips that wrap.
        Flow {
            x: Theme.spacing.m
            width: parent.width - Theme.spacing.m * 2
            visible: root.items.length > 0
            spacing: Theme.spacing.xs

            Repeater {
                model: root.items

                Rectangle {
                    id: chipBox
                    required property var modelData
                    width: chip.implicitWidth + Theme.spacing.m * 2
                    height: Theme.slider.height
                    radius: height / 2
                    color: Colors.tint

                    Row {
                        id: chip
                        anchors.centerIn: parent
                        spacing: Theme.spacing.xs

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: chipBox.modelData.icon
                            color: Colors.m3primary
                            font.pixelSize: Theme.icon.small
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            // A long event title is cut short so the chip fits the card.
                            width: Math.min(implicitWidth, body.width - Theme.spacing.m * 4 - Theme.icon.small - chip.spacing)
                            text: chipBox.modelData.text
                            color: Colors.m3onSurface
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
