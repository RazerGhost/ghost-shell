import QtQuick
import qs.theme

// The ring around a control that has the keyboard (arrow keys or Tab in the island's menus and
// Settings). Only keyboard moves focus to controls, so a click never shows it. Set `radius` to
// the control's. Drawn inside the control's edge: it follows its corners, and a list's clip
// can't cut it off.
Rectangle {
    anchors.fill: parent
    radius: 0
    visible: parent.activeFocus
    color: "transparent"
    border.width: Theme.focus.width
    border.color: Colors.m3primary
}
