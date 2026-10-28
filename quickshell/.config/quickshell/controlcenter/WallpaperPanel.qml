import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The wallpaper picker: the pictures in ~/Pictures/Wallpapers as a grid, wider than the other
// menus so more fit side by side. Click one to use it; the colors follow the picture.
Column {
    id: root

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.s

    // Re-read the folder each time the picker opens: the folder listing doesn't notice the
    // folder being created after the shell started (e.g. by "Open folder").
    onVisibleChanged: {
        if (visible) {
            pictures.folder = "";
            pictures.folder = "file://" + Wallpaper.folder;
        }
    }

    // Title, with a button to open the folder (to add pictures).
    Item {
        width: parent.width - root.leftPadding - root.rightPadding
        height: openFolder.height

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Wallpapers"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
        }

        TextButton {
            id: openFolder
            anchors.right: parent.right
            text: "Open folder"
            onClicked: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && xdg-open "$1"', "sh", Wallpaper.folder])
        }
    }

    GridView {
        id: grid

        readonly property int columns: Theme.wallpaper.columns
        readonly property real thumbWidth: cellWidth - Theme.spacing.s

        width: parent.width - root.leftPadding - root.rightPadding
        cellWidth: width / columns
        cellHeight: thumbWidth * 9 / 16 + Theme.spacing.s
        implicitHeight: Math.min(Math.ceil(count / columns), Theme.wallpaper.rows) * cellHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Accessible.role: Accessible.List

        model: FolderListModel {
            id: pictures
            folder: "file://" + Wallpaper.folder
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
            showDirs: false
            sortField: FolderListModel.Name
        }

        delegate: MouseArea {
            id: cell

            required property string filePath
            required property string fileName
            readonly property bool current: filePath === Wallpaper.path

            width: grid.thumbWidth
            height: grid.cellHeight - Theme.spacing.s
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Wallpaper.set(filePath)

            Accessible.role: Accessible.ListItem
            Accessible.name: fileName + (current ? ", current wallpaper" : "")
            Accessible.onPressAction: Wallpaper.set(filePath)

            ClippingRectangle {
                anchors.fill: parent
                radius: Theme.radius.m
                color: Colors.m3surfaceContainerHigh

                Image {
                    anchors.fill: parent
                    source: "file://" + cell.filePath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    // Thumbnails only; decoding full-size photos would take seconds and memory.
                    sourceSize.width: width * 2
                    Accessible.ignored: true
                }
            }

            // The current wallpaper gets an accent outline; hovered ones a faint one.
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius.m
                color: "transparent"
                border.width: cell.current ? 3 : cell.containsMouse ? 2 : 0
                border.color: cell.current ? Colors.m3primary : Colors.m3onSurface
            }
        }
    }

    Text {
        visible: grid.count === 0
        width: parent.width - root.leftPadding - root.rightPadding
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacing.m
        bottomPadding: Theme.spacing.m
        text: "No pictures yet. Put some in ~/Pictures/Wallpapers (Open folder)."
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }
}
