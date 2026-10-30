import QtQuick
import qs.theme

// One setting in an editor's sheet, like a macOS or iOS sheet: its name on top and its control
// right under it, only as wide as they need (SheetGrid lines them up side by side). An
// optional short subtitle under the name.
Column {
    id: root

    property string title
    property string subtitle
    default property alias control: slot.data

    spacing: Theme.spacing.s

    Column {
        spacing: 2

        Text {
            text: root.title
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.Medium
        }

        Text {
            visible: text !== ""
            width: Math.min(implicitWidth, Math.max(slot.width, Theme.editor.subtitle))
            text: root.subtitle
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: slot
        width: childrenRect.width
        height: childrenRect.height
    }
}
