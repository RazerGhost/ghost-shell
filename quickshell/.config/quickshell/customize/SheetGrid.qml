import QtQuick
import qs.theme

// An editor sheet's tab: its settings (SheetItem, ChoiceCards) side by side at their own
// widths, evenly spaced; a row that fits is centered in the sheet, a longer one wraps.
Flow {
    id: root

    // The children side by side, with the spacing between them.
    readonly property real natural: {
        let width = 0, count = 0;
        for (const child of children) {
            if (child.visible && child.width > 0) {
                width += child.width;
                count++;
            }
        }
        return width + Math.max(count - 1, 0) * spacing;
    }

    width: parent?.width ?? 0
    leftPadding: Math.max(Theme.spacing.l, (width - natural) / 2)
    rightPadding: Theme.spacing.l
    topPadding: Theme.spacing.m
    bottomPadding: Theme.spacing.m
    spacing: Theme.spacing.l * 2
}
