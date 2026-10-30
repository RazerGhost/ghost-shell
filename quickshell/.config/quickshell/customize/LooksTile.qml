import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "Presets.js" as Presets
import "SavedLooks.js" as SavedLooks

// An editor's "Looks" tab: its presets (Presets.js) as picture cards in one row, like the iOS
// lock screen gallery; picking one sets its settings at once, and each can still be changed
// after. "Yours" always comes first: your settings from when the editor opened (`yours`, its
// snapshot for Cancel), so picking it goes back to them; it's the chosen card while no look
// matches. It stays put, so the cards don't shift under the pointer. `art` draws a card: it
// gets `parent.option.values`, the look's settings.
//
// With `savedKey` (the setting holding them), your own looks follow the presets, and a last
// "Save" card keeps the settings now as one (`savedKeys`: what a look of yours keeps). While
// one of yours is chosen, the header has its name to change (Enter) and a delete button.
SheetTile {
    id: tile

    required property var presets
    // The editor's settings when it opened.
    required property var yours
    property Component art
    // Fades the row's end into the tile (the sheet behind it differs per editor).
    property color fadeColor
    property string savedKey: ""
    property var savedKeys: Object.keys(presets[0]?.values ?? {})
    property string savedPrefix: "My look"

    readonly property var saved: savedKey !== "" ? SavedLooks.valid(Settings.values[savedKey], savedKeys) : []
    readonly property var looks: presets.concat(saved)
    readonly property string chosen: Presets.current(Settings.values, looks)
    readonly property bool chosenIsYours: saved.some(l => l.name === chosen)

    function save(): void {
        const look = SavedLooks.made(looks.map(l => l.name), Settings.values, savedKeys, savedPrefix);
        Settings.values[savedKey] = saved.concat([look]);
    }

    title: "Looks"

    // One of yours chosen: its name and delete.
    action: Row {
        visible: tile.chosenIsYours
        spacing: Theme.spacing.xs

        TextField {
            id: lookName
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.editor.slider * 0.7
            placeholder: "Name"
            Accessible.name: "This look's name"
            // Set, not bound: typing would end a binding.
            Component.onCompleted: text = tile.chosen
            onAccepted: Settings.values[tile.savedKey] = SavedLooks.renamed(tile.saved, tile.chosen, text,
                                                                           tile.presets.map(p => p.name))
            Connections {
                target: tile
                function onChosenChanged(): void {
                    lookName.text = tile.chosen;
                }
            }
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "delete"
            label: "Delete " + tile.chosen
            onClicked: Settings.values[tile.savedKey] = SavedLooks.removed(tile.saved, tile.chosen)
        }
    }

    ChoiceCards {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        scrolls: true
        fadeColor: tile.fadeColor
        options: [{ value: "", label: "Yours", values: tile.yours }]
            .concat(tile.looks.map(l => ({ value: l.name, label: l.name, values: l.values })))
            .concat(tile.savedKey !== "" ? [{ value: "<save>", label: "Save this look", save: true, values: {} }] : [])
        current: tile.chosen
        onPicked: v => {
            if (v === "<save>") {
                tile.save();
                return;
            }
            if (v !== "") {
                Presets.apply(Settings.values, tile.looks, v);
                return;
            }
            // Only what these looks set: the other gallery's choice on the tab stays.
            const back = {};
            for (const key of Object.keys(tile.presets[0].values))
                back[key] = tile.yours[key];
            Presets.restore(Settings.values, back);
        }
        // The editor's art, or for the last card a plus.
        art: Component {
            Item {
                id: card
                readonly property var option: parent.option

                Loader {
                    anchors.fill: parent
                    readonly property var option: card.option
                    sourceComponent: card.option.save ? saveArt : tile.art
                }
            }
        }
    }

    Component {
        id: saveArt

        Rectangle {
            color: Colors.tint
            border.width: 1
            border.color: Colors.m3outlineVariant

            MaterialIcon {
                anchors.centerIn: parent
                icon: "add"
                color: Colors.m3onSurfaceVariant
                font.pixelSize: Theme.icon.normal * 1.6
            }
        }
    }
}
