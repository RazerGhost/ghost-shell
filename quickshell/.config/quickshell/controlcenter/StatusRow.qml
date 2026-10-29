import QtQuick
import qs.theme
import qs.widgets

// A line in quick settings about something going on: who uses the microphone, camera or screen
// (like Android's privacy indicators), a screen recording, waiting updates, a network that wants
// you to sign in. An icon, the text, and optionally a button at the right end (`buttonText`;
// `clicked` when pressed).
Item {
    id: root

    property string icon
    property color iconColor: Colors.m3primary
    property int iconSize: Theme.icon.normal
    property string text
    property string buttonText

    signal clicked()

    implicitHeight: buttonText !== "" ? Theme.slider.height : line.implicitHeight

    Row {
        id: line
        anchors.left: parent.left
        anchors.right: button.visible ? button.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: Theme.spacing.s
        spacing: Theme.spacing.s

        MaterialIcon {
            id: glyph
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.icon.normal // the texts line up whatever the icon's size
            horizontalAlignment: Text.AlignHCenter
            icon: root.icon
            color: root.iconColor
            font.pixelSize: root.iconSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            // Several apps' names end in "…" rather than running past the menu.
            width: line.width - line.leftPadding - glyph.width - line.spacing
            elide: Text.ElideRight
            text: root.text
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }
    }

    TextButton {
        id: button
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.xs
        anchors.verticalCenter: parent.verticalCenter
        visible: root.buttonText !== ""
        text: root.buttonText
        onClicked: root.clicked()
    }
}
