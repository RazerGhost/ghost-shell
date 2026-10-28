import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "../services/EmojiData.js" as EmojiData

// The emoji picker (Super+., like Windows): a search field and a grid, the recently used emoji
// first. Arrow keys move through the grid; Enter or a click types the emoji into the window you
// were in. The name of the selected one shows under the grid.
Column {
    id: root

    // An emoji was picked; the island closes and then it's typed (Emoji.type).
    signal picked(string emoji)

    // Recent ones first, then all of them (without repeating the recent ones); while searching,
    // just the matches.
    readonly property var shown: search.text.trim() !== ""
        ? EmojiData.filter(Emoji.all, search.text)
        : Emoji.recent.concat(Emoji.all.filter(e => !Emoji.recent.includes(e)))
    readonly property var current: shown[grid.currentIndex] ?? null

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.s

    onVisibleChanged: {
        if (visible) {
            search.text = "";
            grid.currentIndex = 0;
            search.focusInput();
        }
    }

    SearchField {
        id: search

        width: parent.width - root.leftPadding - root.rightPadding
        placeholder: "Search emoji"

        onTextChanged: grid.currentIndex = 0
        onKeyPressed: event => {
            switch (event.key) {
            case Qt.Key_Right:
                grid.moveCurrentIndexRight();
                break;
            case Qt.Key_Left:
                grid.moveCurrentIndexLeft();
                break;
            case Qt.Key_Down:
                grid.moveCurrentIndexDown();
                break;
            case Qt.Key_Up:
                grid.moveCurrentIndexUp();
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (root.current)
                    root.picked(root.current.emoji);
                break;
            default:
                return; // typing goes to the field
            }
            event.accepted = true;
        }
    }

    GridView {
        id: grid

        readonly property int columns: Math.floor(width / Theme.emoji.cell)

        width: parent.width - root.leftPadding - root.rightPadding
        height: Theme.emoji.rows * Theme.emoji.cell
        cellWidth: width / columns
        cellHeight: Theme.emoji.cell
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0
        // Built only while open: thousands of emoji glyphs cost time and memory.
        model: root.visible ? root.shown : []

        Accessible.role: Accessible.List
        Accessible.name: "Emoji"

        highlight: Rectangle {
            radius: Theme.radius.m
            color: Colors.m3surfaceContainerHighest
        }

        delegate: MouseArea {
            id: cell

            required property var modelData
            required property int index

            width: grid.cellWidth
            height: grid.cellHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: grid.currentIndex = index
            onClicked: root.picked(modelData.emoji)

            Accessible.role: Accessible.ListItem
            Accessible.name: modelData.name
            Accessible.onPressAction: root.picked(modelData.emoji)

            Text {
                anchors.centerIn: parent
                text: cell.modelData.emoji
                font.pixelSize: Theme.emoji.size
                // Colored glyphs from the system's emoji font (Noto Color Emoji).
                font.family: Theme.font.emoji
            }
        }
    }

    // The selected emoji's name (and how many matched while searching).
    Text {
        width: parent.width - root.leftPadding - root.rightPadding
        text: Emoji.all.length === 0 ? "No emoji list: install the unicode-emoji package"
            : root.shown.length === 0 ? "No emoji found"
            : root.current?.name ?? ""
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        elide: Text.ElideRight
    }
}
