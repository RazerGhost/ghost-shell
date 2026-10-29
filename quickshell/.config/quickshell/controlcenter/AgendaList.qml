import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The next few calendar events under the weather (services/Agenda.qml), only once a calendar is
// subscribed (ghost calendar add): "Today 14:00", "Tomorrow", "Mon 2 Nov 09:30", then the title.
Column {
    id: root

    visible: Agenda.enabled
    spacing: Theme.spacing.xs

    readonly property var locale: Qt.locale(Qt.uiLanguage) // English day names, like the date above

    function when(event: var): string {
        const day = new Date(event.start + "T00:00");
        const tomorrow = new Date(Date.now() + 86400000);
        const label = event.start <= Agenda.today ? "Today"
                    : event.start === Qt.formatDate(tomorrow, "yyyy-MM-dd") ? "Tomorrow"
                    : day.toLocaleDateString(locale, "ddd d MMM");
        return event.allDay || event.start < Agenda.today ? label : label + " " + event.startTime;
    }

    Repeater {
        model: Agenda.upcoming

        Row {
            id: event

            required property var modelData

            width: root.width
            leftPadding: Theme.spacing.xs
            spacing: Theme.spacing.s

            Accessible.role: Accessible.StaticText
            Accessible.name: root.when(modelData) + ", " + modelData.title

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "event"
                color: Colors.m3primary
            }

            Text {
                id: time
                anchors.verticalCenter: parent.verticalCenter
                text: root.when(event.modelData)
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: event.width - time.width - Theme.icon.normal - Theme.spacing.s * 2 - event.leftPadding
                text: event.modelData.title
                elide: Text.ElideRight
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
            }
        }
    }

    Text {
        visible: Agenda.upcoming.length === 0
        leftPadding: Theme.spacing.xs
        text: "Nothing on the calendar this week"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
