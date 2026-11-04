import QtQuick
import qs.services
import qs.theme
import "../services/EmojiData.js" as EmojiData

// The launcher's emoji mode (": words", Super+.; Fuzzy.mode): a grid of emoji, the recently used
// first, or the matches for `query`. The launcher's field keeps the keyboard and passes the arrow
// keys (`move`) and Enter (`pick`) here. Picking one types it into the window you were in
// (Emoji.type). Until 2026-11-04 it was a menu of its own in the island.
Column {
    id: root

    property string query: ""
    signal picked(string emoji)

    // Recent ones first, then all of them (without repeating the recent ones); while searching,
    // just the matches.
    readonly property var shown: query.trim() !== ""
        ? EmojiData.filter(Emoji.all, query)
        : Emoji.recent.concat(Emoji.all.filter(e => !Emoji.recent.includes(e)))
    readonly property var current: shown[grid.currentIndex] ?? null

    spacing: Theme.spacing.s
    onQueryChanged: grid.currentIndex = 0

    // An arrow key from the launcher's field; true if it moved.
    function move(key: int): bool {
        switch (key) {
        case Qt.Key_Right: grid.moveCurrentIndexRight(); return true;
        case Qt.Key_Left: grid.moveCurrentIndexLeft(); return true;
        case Qt.Key_Down: grid.moveCurrentIndexDown(); return true;
        case Qt.Key_Up: grid.moveCurrentIndexUp(); return true;
        }
        return false;
    }

    function pick(): void {
        if (current)
            picked(current.emoji);
    }

    GridView {
        id: grid

        readonly property int columns: Math.floor(width / Theme.emoji.cell)

        width: parent.width
        height: Theme.emoji.rows * Theme.emoji.cell
        cellWidth: width / Math.max(columns, 1)
        cellHeight: Theme.emoji.cell
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0
        // Built only while shown: thousands of emoji glyphs cost time and memory.
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

    // The selected emoji's name (or why there's none).
    Text {
        width: parent.width
        text: Emoji.all.length === 0 ? "No emoji list: install the unicode-emoji package"
            : root.shown.length === 0 ? "No emoji found"
            : root.current?.name ?? ""
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        elide: Text.ElideRight
    }
}
