import QtQuick
import qs.theme

// An editor sheet's tab: its settings (SheetItem, ChoiceCards) side by side at their own
// widths, evenly spaced, wrapping only when a row is full.
Flow {
    width: parent?.width ?? 0
    leftPadding: Theme.spacing.l
    rightPadding: Theme.spacing.l
    topPadding: Theme.spacing.m
    bottomPadding: Theme.spacing.m
    spacing: Theme.spacing.l * 2
}
