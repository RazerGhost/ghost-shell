import QtQuick
import qs.theme

// A small status icon whose glyph is the information (quick settings' status icons, the island's
// alerts): MaterialIcon hides its glyph from screen readers, since it's decorative elsewhere, so
// this one reads `label` instead.
MaterialIcon {
    property string label

    anchors.verticalCenter: parent.verticalCenter
    font.pixelSize: Theme.icon.small

    Accessible.name: label
    Accessible.ignored: false
    Accessible.role: Accessible.StaticText
}
