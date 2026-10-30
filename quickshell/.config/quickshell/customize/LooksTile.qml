import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "Presets.js" as Presets
import "SavedLooks.js" as SavedLooks

// An editor's "Looks" tab: its presets (Presets.js) as picture cards in one row, like the iOS
// lock screen gallery; picking one sets its settings at once, and each can still be changed
// after. `art` draws a card over `picture` (a file path: the wallpaper or the lock screen's
// picture): it gets `parent.option.values`, the look's settings.
//
// With `savedKey` (the setting holding them), your own looks follow the presets (`savedKeys`:
// what one keeps), and the row starts with an empty "New look" card: it's the chosen one while
// your settings match no look, and picking it saves them as a new look (as many as you like).
// One of your looks is edited in place, like an iOS lock screen: while it's chosen, changing a
// setting saves the change into it, so it stays chosen (a preset is fixed: changing one leaves
// it for the empty card). Its name can be changed in the header (Enter; Escape puts it back),
// and it can be deleted there. Only while `live` (the editor is open): its Cancel puts
// everything back after closing.
SheetTile {
    id: tile

    required property var presets
    required property bool live
    property Component art
    property string picture
    // Fades the row's end into the tile (the sheet behind it differs per editor).
    property color fadeColor
    property string savedKey: ""
    property var savedKeys: Object.keys(presets[0]?.values ?? {})
    property string savedPrefix: "My look"

    readonly property var saved: savedKey !== "" ? SavedLooks.valid(Settings.values[savedKey], savedKeys) : []
    // Yours first, so an edited look of yours that happens to match a preset stays yours.
    readonly property var looks: saved.concat(presets)
    readonly property string chosen: Presets.current(Settings.values, looks)
    readonly property bool chosenIsYours: saved.some(l => l.name === chosen)
    // The look of yours being edited: picked or just saved; none after picking a preset.
    property string editing: ""

    Component.onCompleted: editing = chosenIsYours ? chosen : ""

    function save(): void {
        const look = SavedLooks.made(looks.map(l => l.name), Settings.values, savedKeys, savedPrefix);
        Settings.values[savedKey] = saved.concat([look]);
        editing = look.name;
    }

    // A setting changed while one of yours was chosen: into it. Once the change has settled (a
    // preset or Cancel sets several at once).
    onChosenChanged: {
        if (chosen === "" && editing !== "" && live)
            follow.restart();
    }

    Timer {
        id: follow
        interval: 0
        onTriggered: {
            if (!tile.live || tile.chosen !== "" || !tile.saved.some(l => l.name === tile.editing))
                return;
            const values = SavedLooks.made([], Settings.values, tile.savedKeys, "").values;
            Settings.values[tile.savedKey] = tile.saved.map(l => l.name === tile.editing ? { name: l.name, values } : l);
        }
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
                const from = tile.chosen;
                Settings.values[tile.savedKey] = SavedLooks.renamed(tile.saved, from, text, tile.presets.map(p => p.name));
                if (tile.editing === from)
                    tile.editing = tile.chosen;
                text = tile.chosen;
            }
            onEscaped: text = tile.chosen
            Connections {
                target: tile
                function onChosenChanged(): void {
                    if (tile.chosen !== "")
                        lookName.text = tile.chosen;
                }
            }
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "delete"
            label: "Delete " + tile.chosen
            onClicked: {
                tile.editing = "";
                Settings.values[tile.savedKey] = SavedLooks.removed(tile.saved, tile.chosen);
            }
        }
    }

    ChoiceCards {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        scrolls: true
        fadeColor: tile.fadeColor
        options: (tile.savedKey !== "" ? [{ value: "", label: "New look", action: true, values: {} }] : [])
            .concat(tile.saved.map(l => ({ value: l.name, label: l.name, values: l.values })))
            .concat(tile.presets.map(p => ({ value: p.name, label: p.name, values: p.values })))
        current: tile.chosen
        onPicked: v => {
            if (v === "") {
                tile.save();
                return;
            }
            Presets.apply(Settings.values, tile.looks, v);
            tile.editing = tile.saved.some(l => l.name === v) ? v : "";
        }
        // The picture with the editor's art over it; the empty card a plus.
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
                    sourceComponent: card.option.action ? newArt : tile.art
                }
            }
        }
    }

    Component {
        id: newArt

        Rectangle {
            color: Colors.tint
            border.width: 1
            border.color: Colors.m3outlineVariant

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacing.xs

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon: "add"
                    color: Colors.m3onSurfaceVariant
                    font.pixelSize: Theme.icon.normal * 1.4
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    // While the settings match no look: they can be kept.
                    text: tile.chosen === "" ? "Save these" : "Save"
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                }
            }
        }
    }
}
