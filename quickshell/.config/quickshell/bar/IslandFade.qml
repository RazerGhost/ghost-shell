import QtQuick
import qs.theme

// One of the things that take the time's place in the closed island (IslandWindow.qml: the time,
// the music, the workspace dots, "Reloaded"). Fills that place; fades in while `shown` and out
// after, and is invisible once faded out, so screen readers skip it.
Item {
    property bool shown

    anchors.fill: parent
    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.anim.normal }
    }
}
