import QtQuick
import qs.theme

// An editor sheet's tab: its settings side by side in as many columns as fit the (full-width)
// sheet, wrapping only when they don't, so the sheet stays short and the card above large.
// A child sizes itself to `cellWidth` times its `span` (SettingRow: one cell, ChoiceCards: two,
// a scrolling ChoiceCards: the whole row); others set their width from `cellWidth` themselves.
Flow {
    readonly property int columns: Math.max(1, Math.floor(width / Theme.editor.cell))
    readonly property real cellWidth: width / columns

    width: parent?.width ?? 0
}
