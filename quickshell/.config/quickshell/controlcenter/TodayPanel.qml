import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import qs.theme
import qs.widgets

// The "today" menu, opened by clicking the time: the date and a month calendar. (Phase 3 adds
// notifications here.)
Column {
    id: root

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
            month = clock.date.getMonth();
            year = clock.date.getFullYear();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        text: Qt.formatDate(clock.date, "dddd, d MMMM")
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.title
        font.weight: Font.DemiBold
    }

    // Month title with previous / next buttons.
    Item {
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
}
