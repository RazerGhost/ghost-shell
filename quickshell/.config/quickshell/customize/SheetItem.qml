import QtQuick
import qs.theme

// One setting in an editor's sheet, like a macOS or iOS sheet: its name on top and its control
// right under it, only as wide as they need (SheetGrid lines them up side by side). The header
// always keeps a line for the subtitle, so every control in a row starts at the same height.
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

        // One line at most, as wide as the control (or the subtitle's own minimum).
        Text {
            width: Math.min(implicitWidth, Math.max(slot.width, Theme.editor.subtitle))
            text: root.subtitle || " "
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    Item {
        id: slot
        width: childrenRect.width
        height: childrenRect.height
    }
}
