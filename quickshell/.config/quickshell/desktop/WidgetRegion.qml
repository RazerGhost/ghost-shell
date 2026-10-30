import QtQuick
import Quickshell

// Where a desktop widget is on the screen, for DesktopWidgets.qml's input and blur regions:
// scaled with its stage, since a Region's `item` doesn't follow the stage's scale while the
// desktop editor shows the widgets in its card.
Region {
    required property Item stage
    required property Item widget
    property real corner: 0

    readonly property bool shown: widget.visible

    x: shown ? stage.x + widget.x * stage.scale : 0
    y: shown ? stage.y + widget.y * stage.scale : 0
    width: shown ? widget.width * stage.scale : 0
    height: shown ? widget.height * stage.scale : 0
    radius: corner * stage.scale
}
