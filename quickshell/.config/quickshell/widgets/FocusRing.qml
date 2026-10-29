import QtQuick
import qs.theme

// The ring around a control that has the keyboard (arrow keys or Tab in the island's menus and
// Settings). Only keyboard moves focus to controls, so a click never shows it. Set `radius` to
// the control's. Drawn inside the control's edge: it follows its corners, and a list's clip
// can't cut it off. `control` is the item whose focus it shows, when that isn't its parent.
Rectangle {
    property Item control: parent

    anchors.fill: parent
    radius: 0
    visible: control?.activeFocus ?? false
    color: "transparent"
    border.width: Theme.focus.width
    border.color: Colors.m3primary
}
