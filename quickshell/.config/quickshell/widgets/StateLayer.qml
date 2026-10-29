import QtQuick
import qs.theme

// A Material "state layer": the content color laid over a control, faint while hovered and a
// little stronger while active (its menu is open). Set `hovered` (and `active`), and `radius` and
// `color` to match the control.
Rectangle {
    property bool hovered
    property bool active

    anchors.fill: parent
    color: Colors.m3onSurface
    opacity: active ? Theme.state.active : hovered ? Theme.state.hover : 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.anim.fast }
    }
}
