import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "../services/ClipboardEntries.js" as ClipboardEntries

// The clipboard menu (Super+V): your pinned texts, then what you copied, newest first, with a
// search field. Click an entry or press Enter to paste it; Delete or × removes one (or unpins
// it); the pin button keeps a text at the top, also through "Clear all".
Column {
    id: root

    // An entry was picked; the island closes and then it's pasted.
    signal picked(var entry)

    readonly property var shown: ClipboardEntries.filter(ClipboardEntries.withPins(Clipboard.pins, Clipboard.entries), search.text)

    function removeEntry(entry: var): void {
        if (entry.pinned)
            Clipboard.unpin(entry.text);
        else
            Clipboard.remove(entry);
    }

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.s

    onVisibleChanged: {
        if (visible) {
            Clipboard.refresh();
            search.text = "";
            search.focusInput();
        }
    }

    SearchField {
        id: search

        width: parent.width - root.leftPadding - root.rightPadding
        placeholder: "Search clipboard"

        onTextChanged: list.currentIndex = 0
        onKeyPressed: event => {
            switch (event.key) {
            case Qt.Key_Down:
                list.incrementCurrentIndex();
                break;
            case Qt.Key_Up:
                list.decrementCurrentIndex();
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (list.currentItem)
                    root.picked(list.currentItem.modelData);
                break;
            case Qt.Key_Delete:
                if (list.currentItem)
                    root.removeEntry(list.currentItem.modelData);
                break;
            default:
                return; // typing goes to the field
            }
            event.accepted = true;
        }

        TextButton {
            visible: Clipboard.entries.length > 0
            text: "Clear all"
            onClicked: Clipboard.wipe()
        }
    }

    ListView {
        id: list

        width: parent.width - root.leftPadding - root.rightPadding
        implicitHeight: Math.min(contentHeight, Theme.clipboard.height)
        clip: true
        spacing: Theme.spacing.xs
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.anim.fast
        model: root.shown

        Accessible.role: Accessible.List

        highlight: Rectangle {
            radius: Theme.radius.m
            color: Colors.m3surfaceContainerHighest
        }

        delegate: MouseArea {
            id: row

            required property var modelData
            required property int index

            width: ListView.view.width
            height: modelData.image ? Theme.clipboard.imageHeight + Theme.spacing.s * 2 : preview.implicitHeight + Theme.spacing.m * 2
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: list.currentIndex = index
            onClicked: root.picked(modelData)

            Accessible.role: Accessible.ListItem
            Accessible.name: modelData.image ? "Image, " + modelData.image.width + " by " + modelData.image.height
                           : (modelData.pinned ? "Pinned, " : "") + modelData.text
            Accessible.onPressAction: root.picked(modelData)

            // A pin's mark.
            MaterialIcon {
                id: pinMark
                visible: row.modelData.pinned ?? false
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.m
                anchors.verticalCenter: parent.verticalCenter
                icon: "keep"
                color: Colors.m3primary
                font.pixelSize: Theme.icon.small
            }

            Text {
                id: preview
                visible: !row.modelData.image
                anchors.left: pinMark.visible ? pinMark.right : parent.left
                anchors.right: buttons.left
                anchors.leftMargin: Theme.spacing.m
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.text
                textFormat: Text.PlainText
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            // Images: decoded into a file once, then shown as a thumbnail.
            ClippingRectangle {
                visible: row.modelData.image !== null
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.clipboard.imageHeight * 16 / 9
                height: Theme.clipboard.imageHeight
                radius: Theme.radius.s
                color: Colors.m3surfaceContainerHigh

                Image {
                    id: thumbnail
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: width * 2
                    Accessible.ignored: true
                }

                Process {
                    readonly property string file: Clipboard.thumbnailDir + "/" + row.modelData.id + "." + (row.modelData.image?.format ?? "")
                    running: row.modelData.image !== null
                    command: ["sh", "-c", 'mkdir -p "$1" && { [ -s "$2" ] || cliphist decode "$3" > "$2"; }',
                              "sh", Clipboard.thumbnailDir, file, row.modelData.id]
                    onExited: thumbnail.source = "file://" + file
                }
            }

            Row {
                id: buttons
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                // Keep it at the top (text only).
                IconButton {
                    visible: row.containsMouse && !row.modelData.image && !row.modelData.pinned
                    icon: "keep"
                    iconSize: Theme.icon.small
                    label: "Pin to the top"
                    onClicked: Clipboard.pin(row.modelData)
                }

                IconButton {
                    visible: row.containsMouse
                    icon: "close"
                    iconSize: Theme.icon.small
                    label: row.modelData.pinned ? "Unpin" : "Remove from clipboard history"
                    onClicked: root.removeEntry(row.modelData)
                }
            }
        }
    }

    Text {
        visible: list.count === 0
        width: parent.width - root.leftPadding - root.rightPadding
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacing.s
        bottomPadding: Theme.spacing.s
        text: Clipboard.entries.length === 0 ? "Nothing copied yet" : "No matches"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
