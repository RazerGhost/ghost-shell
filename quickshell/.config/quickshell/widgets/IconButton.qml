import QtQuick
import qs.theme

// A round icon button with a hover highlight. `label` is what screen readers announce.
Item {
    id: root

    property alias icon: glyph.icon
    property alias color: glyph.color
    property alias iconSize: glyph.font.pixelSize
    property string label

    signal clicked(int button)
    // Wheel notches, positive = up. Touchpads send fractions of a notch.
    signal scrolled(real steps)

    implicitWidth: glyph.font.pixelSize + Theme.spacing.s * 2
    implicitHeight: implicitWidth

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: root.clicked(Qt.LeftButton)

    // Hover highlight (a Material "state layer").
    StateLayer {
        radius: Theme.radius.full
        color: glyph.color
        hovered: mouse.containsMouse
    }

    MaterialIcon {
        id: glyph
        anchors.centerIn: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => root.scrolled(event.angleDelta.y / 120)
    }
}
