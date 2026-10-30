import QtQuick
import qs.theme
import qs.widgets

// A desktop widget's card: glass like the shell's panels, small (a square) or medium (twice as
// wide), every widget the same height, corners and padding (Theme.desktop). The content goes
// inside the padding.
Surface {
    id: root

    property bool medium: false
    default property alias content: inner.data

    implicitWidth: medium ? Theme.desktop.medium : Theme.desktop.size
    implicitHeight: Theme.desktop.size
    width: implicitWidth
    height: implicitHeight
    radius: Theme.desktop.radius

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: Theme.desktop.padding
    }
}
