import QtQuick
import qs.theme
import qs.widgets

// A desktop widget's card: glass like the shell's panels, small (a square), medium (twice as
// wide) or large (that, twice as tall), every widget the same corners and padding
// (Theme.desktop). The content goes inside the padding.
Surface {
    id: root

    property bool medium: false
    property bool large: false
    default property alias content: inner.data

    implicitWidth: medium || large ? Theme.desktop.medium : Theme.desktop.size
    implicitHeight: large ? Theme.desktop.medium : Theme.desktop.size
    width: implicitWidth
    height: implicitHeight
    radius: Theme.desktop.radius
    color: Colors.widgetTranslucent

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: Theme.desktop.padding
    }
}
