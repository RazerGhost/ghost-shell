import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// The notifications widget (small): how many are waiting in the today menu, and from how many
// apps; never what they say (the lock screen shows it too). Clicking it opens the today menu.
WidgetSurface {
    id: widget

    readonly property int count: Notifications.history.length
    readonly property int apps: new Set(Notifications.history.map(n => n.appName)).size

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: openToday()

        function openToday(): void {
            Quickshell.execDetached(["qs", "ipc", "call", "island", "toggle", "today"]);
        }

        Accessible.role: Accessible.Button
        Accessible.name: (widget.count === 1 ? "1 notification" : widget.count + " notifications") + ": open the today menu"
        Accessible.onPressAction: openToday()
    }

    MaterialIcon {
        anchors.top: parent.top
        anchors.right: parent.right
        icon: widget.count > 0 ? "notifications_unread" : "notifications"
        color: widget.count > 0 ? Colors.m3primary : Colors.m3onSurfaceVariant
        font.pixelSize: Theme.desktop.icon
    }

    Text {
        anchors.top: parent.top
        text: widget.count
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.desktop.clock
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }

    Column {
        anchors.bottom: parent.bottom
        width: parent.width

        Text {
            width: parent.width
            text: widget.count === 1 ? "Notification" : "Notifications"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: widget.count === 0 ? "All caught up" : widget.apps === 1 ? "From 1 app" : "From " + widget.apps + " apps"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }
}
