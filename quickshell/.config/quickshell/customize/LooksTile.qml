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
// gets `parent.option.values`, the look's settings, and draws over `picture` (a file path, the
// card's backdrop: the wallpaper or the lock screen's picture).
//
// With `savedKey` (the setting holding them), your own looks follow the presets, and while your
// settings match none of them a last "Save" card keeps them as one (`savedKeys`: what a look of
// yours keeps; saving one that matches would make a look that can never be chosen). While one
// of yours is chosen, the header has its name to change (Enter; Escape puts it back) and a
// delete button.
SheetTile {
    id: tile

    required property var presets
    // The editor's settings when it opened.
    required property var yours
    property Component art
    property string picture
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
            keepsEscape: true
            Accessible.name: "This look's name"
            // Set, not bound: typing would end a binding.
            Component.onCompleted: text = tile.chosen
            // A name that's empty or taken isn't kept: the field shows the name again.
            onAccepted: {
                Settings.values[tile.savedKey] = SavedLooks.renamed(tile.saved, tile.chosen, text, tile.presets.map(p => p.name));
                text = tile.chosen;
            }
            onEscaped: text = tile.chosen
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
            .concat(tile.savedKey !== "" && tile.chosen === "" ? [{ value: "<save>", label: "Save this look", action: true, values: {} }] : [])
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
            // What these looks set (all of it for a look of yours): the other gallery's choice on
            // the tab stays.
            const back = {};
            for (const key of tile.savedKeys)
                back[key] = tile.yours[key];
            Presets.restore(Settings.values, back);
        }
        // The picture, the editor's art over it; for the last card a plus.
        art: Component {
            Item {
                id: card
                readonly property var option: parent.option

                Image {
                    anchors.fill: parent
                    visible: !card.option.action
                    source: tile.picture ? "file://" + tile.picture : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: width * 2
                    asynchronous: true
                }

                Loader {
                    anchors.fill: parent
                    readonly property var option: card.option
                    sourceComponent: card.option.action ? saveArt : tile.art
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
