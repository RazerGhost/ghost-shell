import QtQuick
import qs.theme
import qs.widgets

// One line under the lock screen's date (LockStatus.qml): an icon and a short text.
Row {
    id: root

    property string icon
    property string text

    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Theme.spacing.s

    Accessible.role: Accessible.StaticText
    Accessible.name: text

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        color: Colors.m3onSurfaceVariant
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
