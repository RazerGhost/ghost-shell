import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "NotificationGroups.js" as NotificationGroups

// The "today" menu, opened by clicking the time: the date, the weather, the next calendar
// events, the note and timer, and the notification history. The month and the to-do list are
// desktop widgets of their own (desktop/MonthWidget.qml, TasksWidget.qml; user's choice,
// 2026-11-04: they didn't fit in the island).
Column {
    id: root

    // The apps whose notifications are all shown (the others show their newest). Folded every
    // time the menu opens.
    property list<string> expandedApps: []

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.m

    onVisibleChanged: {
        if (visible) {
            tools.open = "";
            expandedApps = [];
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The date (the month is a desktop widget of its own: desktop/MonthWidget.qml).
    Text {
        width: parent.width - root.leftPadding - root.rightPadding
        text: Qt.formatDate(clock.date, "dddd, d MMMM")
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.title
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        Accessible.role: Accessible.Heading
        Accessible.name: text
    }

    // The weather where you are.
    WeatherRow {
        width: parent.width - root.leftPadding - root.rightPadding
    }

    AgendaList {
        width: parent.width - root.leftPadding - root.rightPadding
    }

    TodayTools {
        id: tools
        width: parent.width - root.leftPadding - root.rightPadding
    }

    // Notifications, newest first.
    Column {
        width: parent.width - root.leftPadding - root.rightPadding
        spacing: Theme.spacing.s

        Item {
            width: parent.width
            height: clearAll.height

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                font.weight: Font.DemiBold
            }

            TextButton {
                id: clearAll
                anchors.right: parent.right
                visible: Notifications.history.length > 0
                text: "Clear all"
                onClicked: Notifications.clearAll()
            }
        }

        Text {
            visible: Notifications.history.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            bottomPadding: Theme.spacing.s
            text: "No notifications"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }

        Flickable {
            visible: Notifications.history.length > 0
            width: parent.width
            height: Math.min(contentHeight, Theme.notifications.historyHeight)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Grouped by app (NotificationGroups.js, tested), the groups by their newest
            // notification. A group shows its newest card; "+N more" shows the rest.
            Column {
                id: list
                width: parent.width
                spacing: Theme.spacing.m

                Repeater {
                    model: ScriptModel {
                        values: NotificationGroups.groups(Notifications.history.map(n => Notifications.appOf(n)))
                            .map(g => ({ app: g.app, notifications: g.indices.map(i => Notifications.history[i]) }))
                        objectProp: "app"
                    }

                    Column {
                        id: group

                        required property var modelData
                        readonly property bool expanded: root.expandedApps.includes(modelData.app)
                        readonly property int hidden: modelData.notifications.length - 1

                        width: list.width
                        spacing: Theme.spacing.s

                        // The app, its count, and × for all of its notifications.
                        Item {
                            width: parent.width
                            height: clearGroup.height
                            visible: group.modelData.notifications.length > 1

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacing.s
                                anchors.verticalCenter: parent.verticalCenter
                                text: (group.modelData.app || "Other") + " · " + group.modelData.notifications.length
                                color: Colors.m3onSurfaceVariant
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.small
                                font.weight: Font.DemiBold
                            }

                            IconButton {
                                id: clearGroup
                                anchors.right: parent.right
                                icon: "close"
                                label: "Clear " + (group.modelData.app || "these") + " notifications"
                                iconSize: Theme.icon.small
                                onClicked: group.modelData.notifications.forEach(n => n?.dismiss())
                            }
                        }

                        Repeater {
                            model: group.expanded ? group.modelData.notifications : group.modelData.notifications.slice(0, 1)

                            NotificationCard {
                                required property var modelData
                                width: list.width
                                notification: modelData
                                now: clock.date.getTime() // ticks every minute
                                canType: true
                            }
                        }

                        TextButton {
                            visible: group.hidden > 0
                            text: group.expanded ? "Show less" : "+" + group.hidden + " more"
                            onClicked: root.expandedApps = group.expanded
                                ? root.expandedApps.filter(a => a !== group.modelData.app)
                                : [...root.expandedApps, group.modelData.app]
                        }
                    }
                }
            }
        }
    }
}
