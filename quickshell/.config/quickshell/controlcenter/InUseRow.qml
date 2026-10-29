import QtQuick
import qs.theme
import qs.widgets

// A line in quick settings saying who uses the microphone, camera or screen, shown only while
// one is in use (like Android's privacy indicators).
Row {
    id: root

    property string icon
    property string text

    leftPadding: Theme.spacing.s
    spacing: Theme.spacing.s

    MaterialIcon {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        color: Colors.m3primary
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        // Several apps' names end in "…" rather than running past the menu.
        width: root.width - root.leftPadding - glyph.width - root.spacing
        elide: Text.ElideRight
        text: root.text
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
