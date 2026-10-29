import QtQuick
import qs.theme
import qs.widgets

// The island's note after the shell reloads (a file in its folder changed): "Shell reloaded",
// centered, or "Shell reload failed" with the error across the full width (the old shell keeps
// running then). Replaces Quickshell's own pop-up.
Row {
    id: root

    property string error

    readonly property bool failed: error !== ""

    anchors.horizontalCenter: parent.horizontalCenter
    y: Theme.spacing.m
    width: failed ? parent.width - Theme.spacing.l * 2 : implicitWidth
    spacing: Theme.spacing.m

    MaterialIcon {
        id: icon
        anchors.verticalCenter: root.failed ? undefined : parent.verticalCenter
        icon: root.failed ? "error" : "check_circle"
        color: root.failed ? Colors.m3error : Colors.m3primary
    }

    Column {
        width: root.failed ? parent.width - icon.width - parent.spacing : implicitWidth
        spacing: Theme.spacing.xs

        Text {
            text: root.failed ? "Shell reload failed" : "Shell reloaded"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.error
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.mono
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
            maximumLineCount: 6
            elide: Text.ElideRight
        }
    }
}
