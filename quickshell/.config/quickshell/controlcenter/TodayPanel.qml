import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// The "today" menu, opened by clicking the time: the date, the weather, the notification
// history, and a month calendar that stays folded away until you click the date.
Column {
    id: root

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
            required property bool today

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

            Column {
                id: list
                width: parent.width
                spacing: Theme.spacing.s

                Repeater {
                    // ScriptModel: a new notification adds one card instead of rebuilding all.
                    model: ScriptModel { values: [...Notifications.history] }

                    NotificationCard {
                        required property var modelData
                        width: list.width
                        notification: modelData
                        now: clock.date.getTime() // ticks every minute
                        canType: true
                    }
                }
            }
        }
    }
}
