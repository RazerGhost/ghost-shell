import QtQuick
import qs.theme
import qs.widgets

// A button in a window's title bar (WindowTitleBar.qml), like GTK's: a faint circle behind the icon.
IconButton {
    iconSize: Theme.icon.small
    color: Colors.m3onSurface

    Rectangle {
        anchors.fill: parent
        z: -1
        radius: Theme.radius.full
        color: Colors.m3onSurface
        opacity: 0.1
    }
}
