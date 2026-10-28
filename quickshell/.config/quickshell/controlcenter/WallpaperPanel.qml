import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The wallpaper picker: the island stretches across the whole top edge and shows one row of
// pictures, scrolling sideways (the mouse wheel too). Your pictures from ~/Pictures/Wallpapers
// come first, then the built-in ones that come with Hyprland and CachyOS (from their packages,
// so they're not copied anywhere). Click one to use it; the colors follow the picture.
Column {
    id: root

    // Thumbnails only load once the picker has been opened: the built-in pictures are large
    // (up to 5K), and decoding them all at login would keep the CPU busy for nothing.
    property bool opened: false

    readonly property real contentWidth: width - leftPadding - rightPadding
    readonly property real thumbHeight: Theme.wallpaper.thumbHeight
    readonly property real thumbWidth: thumbHeight * 16 / 9

    // The pictures in a FolderListModel as { filePath, fileName }, so all three folders can
    // share one row.
    function files(model: FolderListModel): var {
        const list = [];
        for (let i = 0; i < model.count; i++)
            list.push({ filePath: model.get(i, "filePath"), fileName: model.get(i, "fileName") });
        return list;
    }

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.s

    // Re-read your folder each time the picker opens: the folder listing doesn't notice the
    // folder being created after the shell started (e.g. by "Open folder").
    onVisibleChanged: {
        if (visible) {
            opened = true;
            yours.folder = "";
            yours.folder = "file://" + Wallpaper.folder;
        }
    }

    FolderListModel {
        id: yours
        folder: "file://" + Wallpaper.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    FolderListModel {
        id: hyprland
        folder: "file:///usr/share/hypr"
        nameFilters: ["wall*.png"] // the folder also holds other images
        showDirs: false
    }

    FolderListModel {
        id: cachyos
        folder: "file:///usr/share/wallpapers/cachyos-wallpapers"
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    // One picture in the grid. The current wallpaper gets an accent outline.
    component Thumbnail: MouseArea {
        id: cell

        required property var modelData
        readonly property string filePath: modelData.filePath
        readonly property string fileName: modelData.fileName
        readonly property bool current: filePath === Wallpaper.path

        width: root.thumbWidth
        height: root.thumbHeight
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
                source: root.opened ? "file://" + cell.filePath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Thumbnails only; decoding full-size pictures would take seconds and memory.
                sourceSize.width: width * 2
                Accessible.ignored: true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.m
            color: "transparent"
            border.width: cell.current ? 3 : cell.containsMouse ? 2 : 0
            border.color: cell.current ? Colors.m3primary : Colors.m3onSurface
        }
    }

    // Title, with a button to open your folder (to add pictures).
    Item {
        width: root.contentWidth
        height: openFolder.height

        Text {
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.StyledText
            text: "Wallpapers" + (yours.count === 0
                  ? "<font color='" + Colors.m3onSurfaceVariant + "'>  ·  add your own to ~/Pictures/Wallpapers</font>" : "")
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

    ListView {
        width: root.contentWidth
        height: root.thumbHeight
        orientation: ListView.Horizontal
        spacing: Theme.spacing.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // files() reads each folder's count, so the row updates when a folder changes.
        model: root.files(yours).concat(root.files(hyprland), root.files(cachyos))
        delegate: Thumbnail {}

        Accessible.role: Accessible.List
        Accessible.name: "Wallpapers"
    }
}
