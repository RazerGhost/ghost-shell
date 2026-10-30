import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "Presets.js" as Presets

// An editor's "Looks" tab: its presets (Presets.js) as picture cards in one row, like the iOS
// lock screen gallery; picking one sets its settings at once, and each can still be changed
// after. While your settings match none of them, "Yours" comes first. `art` draws a card: it
// gets `parent.option.values`, the look's settings (yours for "Yours").
SheetTile {
    id: tile

    required property var presets
    property Component art
    // Fades the row's end into the tile (the sheet behind it differs per editor).
    property color fadeColor

    readonly property string chosen: Presets.current(Settings.values, presets)

    title: "Looks"

    ChoiceCards {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        scrolls: true
        fadeColor: tile.fadeColor
        options: (tile.chosen === "" ? [{ value: "", label: "Yours", values: Settings.values }] : [])
            .concat(tile.presets.map(p => ({ value: p.name, label: p.name, values: p.values })))
        current: tile.chosen
        onPicked: v => {
            if (v !== "")
                Presets.apply(Settings.values, tile.presets, v);
        }
        art: tile.art
    }
}
