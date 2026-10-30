import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "Presets.js" as Presets

// An editor's "Looks" tab: its presets (Presets.js) as picture cards in one row, like the iOS
// lock screen gallery; picking one sets its settings at once, and each can still be changed
// after. "Yours" always comes first: your settings from when the editor opened (`yours`, its
// snapshot for Cancel), so picking it goes back to them; it's the chosen card while no preset
// matches. It stays put, so the cards don't shift under the pointer. `art` draws a card: it
// gets `parent.option.values`, the look's settings.
SheetTile {
    id: tile

    required property var presets
    // The editor's settings when it opened.
    required property var yours
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
        options: [{ value: "", label: "Yours", values: tile.yours }]
            .concat(tile.presets.map(p => ({ value: p.name, label: p.name, values: p.values })))
        current: tile.chosen
        onPicked: v => {
            if (v !== "") {
                Presets.apply(Settings.values, tile.presets, v);
                return;
            }
            // Only what these presets set: the other gallery's choice on the tab stays.
            const back = {};
            for (const key of Object.keys(tile.presets[0].values))
                back[key] = tile.yours[key];
            Presets.restore(Settings.values, back);
        }
        art: tile.art
    }
}
