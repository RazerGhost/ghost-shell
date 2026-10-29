import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "NotificationGroups.js" as NotificationGroups

// The "today" menu, opened by clicking the time: the date, the weather, the next calendar
// events, the to-do list, note and timer, the notification history, and a month calendar that stays folded away until you
// click the date.
Column {
    id: root

    // The apps whose notifications are all shown (the others show their newest). Folded every
    // time the menu opens.
    property list<string> expandedApps: []

    // Whether the month calendar is shown. Folded every time the menu opens.
    property bool calendarOpen: false
    // The month the calendar shows. Back to the current month every time the menu opens.
    property int month: clock.date.getMonth()
    property int year: clock.date.getFullYear()

    function showMonth(offset: int): void {
        const first = new Date(year, month + offset, 1);
        month = first.getMonth();
        year = first.getFullYear();
    }

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.m

    onVisibleChanged: {
        if (visible) {
            calendarOpen = false;
            tools.open = "";
            expandedApps = [];
            month = clock.date.getMonth();
            year = clock.date.getFullYear();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The date; click it to show or hide the month calendar.
    MouseArea {
        width: parent.width - root.leftPadding - root.rightPadding
        implicitHeight: date.implicitHeight
        cursorShape: Qt.PointingHandCursor
        onClicked: root.calendarOpen = !root.calendarOpen

        Accessible.role: Accessible.Button
        Accessible.name: date.text + (root.calendarOpen ? ", hide calendar" : ", show calendar")
        Accessible.onPressAction: root.calendarOpen = !root.calendarOpen

        // The keyboard (arrow keys or Tab, then Enter or Space), like a click.
        activeFocusOnTab: true
        Keys.onReturnPressed: root.calendarOpen = !root.calendarOpen
        Keys.onEnterPressed: root.calendarOpen = !root.calendarOpen
        Keys.onSpacePressed: root.calendarOpen = !root.calendarOpen

        FocusRing {
            radius: Theme.radius.s
        }

        Text {
            id: date
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(clock.date, "dddd, d MMMM")
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.title
            font.weight: Font.DemiBold
        }

        MaterialIcon {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: "expand_more"
            color: Colors.m3onSurfaceVariant
            rotation: root.calendarOpen ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
            }
        }
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

    // Month title with previous / next buttons.
    Item {
        visible: root.calendarOpen
        width: parent.width - root.leftPadding - root.rightPadding
        implicitHeight: Theme.slider.height

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.xs
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            IconButton {
                icon: "chevron_left"
                label: "Previous month"
                onClicked: root.showMonth(-1)
            }

            IconButton {
                icon: "chevron_right"
                label: "Next month"
                onClicked: root.showMonth(1)
            }
        }
    }

    // DayOfWeekRow and MonthGrid come with Qt Quick Controls; only the cells are drawn here.
    // Day names and the first day of the week follow the UI language (en_GB: Monday), so
    // they match the English date above even with Dutch regional formats (LC_TIME=nl_NL).
    DayOfWeekRow {
        visible: root.calendarOpen
        width: parent.width - root.leftPadding - root.rightPadding
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

    // The calendar's events for the month shown (dots under their days).
    Binding {
        target: Agenda
        property: "year"
        value: root.year
    }

    Binding {
        target: Agenda
        property: "month"
        value: root.month
    }

    MonthGrid {
        id: grid

        visible: root.calendarOpen
        width: parent.width - root.leftPadding - root.rightPadding
        month: root.month
        year: root.year
        locale: Qt.locale(Qt.uiLanguage)
        // MonthGrid always lays out 6 weeks and doesn't size itself.
        implicitHeight: Theme.island.height * 6

        delegate: Item {
            id: cell

            required property int day
            required property int month
            required property int year
            required property bool today
            readonly property bool hasEvent: Agenda.days[`${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`] === true

            implicitHeight: Theme.island.height

            Rectangle {
                anchors.centerIn: parent
                width: Theme.island.height - Theme.spacing.xs
                height: width
                radius: Theme.radius.full
                color: Colors.m3primary
                visible: cell.today
            }

            Text {
                anchors.centerIn: parent
                text: cell.day
                color: cell.today ? Colors.m3onPrimary : Colors.m3onSurface
                // Days from the previous and next month fill the grid, dimmed.
                opacity: cell.month === grid.month ? 1 : 0.35
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                font.weight: cell.today ? Font.DemiBold : Font.Normal
            }

            // A day with a calendar event.
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacing.xs / 2
                width: Theme.spacing.xs
                height: width
                radius: width / 2
                visible: cell.hasEvent && !cell.today
                color: Colors.m3primary
                opacity: cell.month === grid.month ? 1 : 0.35
            }
        }
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
                        values: NotificationGroups.groups(Notifications.history.map(n => n?.appName ?? ""))
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
