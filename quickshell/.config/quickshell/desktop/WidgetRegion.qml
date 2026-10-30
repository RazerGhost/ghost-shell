import QtQuick
import Quickshell

// Where a desktop widget is on the screen, for DesktopWidgets.qml's input and blur regions:
// scaled with its stage (the desktop editor's card) and its own scale (it lifts under the
// pointer and grows in when shown), around its middle, since a Region's `item` follows neither.
Region {
    required property Item stage
    required property Item widget
    property real corner: 0

    readonly property bool shown: widget.visible

    x: shown ? stage.x + (widget.x + widget.width * (1 - widget.scale) / 2) * stage.scale : 0
    y: shown ? stage.y + (widget.y + widget.height * (1 - widget.scale) / 2) * stage.scale : 0
    width: shown ? widget.width * widget.scale * stage.scale : 0
    height: shown ? widget.height * widget.scale * stage.scale : 0
    radius: corner * widget.scale * stage.scale
}
