import QtQuick
import qs.theme
import qs.widgets

// A choice as a chip in an editor tile (the blur styles, the fonts): filled while chosen. With
// `sample` it shows "Aa" in `sampleFont` above its name.
Rectangle {
    id: root

    property string text
    property bool chosen
    property bool sample: false
    property string sampleFont

    signal clicked()

    implicitHeight: sample ? Theme.editor.fontChip : Theme.island.height
    radius: Theme.radius.m
    color: chosen ? Colors.m3primaryContainer
                  : Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, 0.06)
    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

    Accessible.role: Accessible.RadioButton
    Accessible.name: text
    Accessible.checked: chosen
    Accessible.onPressAction: root.clicked()
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.spacing.s * 2

        Text {
            width: parent.width
            visible: root.sample
            horizontalAlignment: Text.AlignHCenter
            text: "Aa"
            color: root.chosen ? Colors.m3onPrimaryContainer : Colors.m3onSurface
            font.family: root.sampleFont
            font.pixelSize: Theme.font.title
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.text
            color: root.chosen ? Colors.m3onPrimaryContainer : Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: root.sample ? Theme.font.small : Theme.font.normal
            font.weight: root.chosen ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
        }
    }

    StateLayer {
        radius: root.radius
        color: Colors.m3onSurface
        hovered: mouse.containsMouse
    }

    FocusRing {
        radius: root.radius
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
