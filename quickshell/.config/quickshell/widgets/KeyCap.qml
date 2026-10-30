import QtQuick
import qs.theme

// One key as a key cap ("Super", "Tab", "←"): Settings -> Keybinds, the welcome tour, the
// editors' and the customize menu's key hints.
Rectangle {
    id: root

    property string text

    width: Math.max(height, cap.implicitWidth + Theme.spacing.m)
    height: cap.implicitHeight + Theme.spacing.xs * 2
    radius: Theme.radius.s
    color: Colors.m3surfaceContainerHighest
    border.width: 1
    border.color: Colors.m3outlineVariant

    Text {
        id: cap
        anchors.centerIn: parent
        text: root.text
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        font.weight: Font.Medium
    }
}
