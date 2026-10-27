import QtQuick
import qs.theme

// Rounded, content-sized container for a group of bar modules.
// Children go into the row (default property alias), laid out left to right.
Rectangle {
    default property alias content: row.data

    implicitWidth: row.implicitWidth + Theme.spacing.l * 2
    implicitHeight: Theme.bar.height
    radius: Theme.radius.full
    color: Qt.rgba(Colors.m3surfaceContainer.r, Colors.m3surfaceContainer.g, Colors.m3surfaceContainer.b, Theme.bar.opacity)

    // Animate width changes so the bar grows and shrinks smoothly.
    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing.m
    }
}
