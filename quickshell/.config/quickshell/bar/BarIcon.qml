import QtQuick
import qs.theme
import qs.widgets

// A status icon in a bar pill. Set `interactive` and handle onClicked / onScrolled to make
// it a button; `label` is what screen readers announce.
Item {
    id: root

    property alias icon: glyph.icon
    property alias color: glyph.color
    property string label
    property bool interactive: false

    signal clicked(int button)
    // Wheel notches, positive = up. Touchpads send fractions of a notch.
    signal scrolled(real steps)

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: Theme.icon.bar + Theme.spacing.xs * 2
    implicitHeight: implicitWidth

    Accessible.role: interactive ? Accessible.Button : Accessible.StaticText
    Accessible.name: label
    Accessible.onPressAction: root.clicked(Qt.LeftButton)

    // Hover highlight (a Material "state layer").
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.full
        color: Colors.m3onSurface
        opacity: mouse.containsMouse ? 0.12 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.anim.fast }
        }
    }

    MaterialIcon {
        id: glyph
        anchors.centerIn: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => root.scrolled(event.angleDelta.y / 120)
    }
}
