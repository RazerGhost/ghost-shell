import QtQuick
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets

// Under the clock on the lock screen (not the login screen): the media player, like the island's
// small one, and how many notifications came in, never what they say (anyone can read a locked
// screen). Each can be turned off in Settings -> Lock screen.
Column {
    spacing: Theme.spacing.m

    MediaCard {
        width: parent.width
        visible: Settings.values.lockMedia && player !== null
    }

    Row {
        readonly property int count: Notifications.history.length

        anchors.horizontalCenter: parent.horizontalCenter
        visible: Settings.values.lockNotificationCount && count > 0
        spacing: Theme.spacing.s

        Accessible.role: Accessible.StaticText
        Accessible.name: label.text

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: "notifications"
            color: Colors.m3onSurfaceVariant
        }

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: parent.count === 1 ? "1 notification" : parent.count + " notifications"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }
    }
}
