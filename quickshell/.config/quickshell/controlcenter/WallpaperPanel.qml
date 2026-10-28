import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The wallpaper picker, wider than the other menus: your pictures from ~/Pictures/Wallpapers in
// one row, then the built-in ones that come with Hyprland and CachyOS (from their packages, so
// they're not copied anywhere) in two rows. Both scroll sideways (the mouse wheel too). Click
// one to use it; the colors follow the picture.
Column {
    id: root

    // Thumbnails only load once the picker has been opened: the built-in pictures are large
    // (up to 5K), and decoding them all at login would keep the CPU busy for nothing.
    property bool opened: false

    readonly property real contentWidth: width - leftPadding - rightPadding
    readonly property real thumbWidth: (contentWidth - Theme.spacing.s * (Theme.wallpaper.columns - 1)) / Theme.wallpaper.columns
    readonly property real thumbHeight: thumbWidth * 9 / 16

    // The pictures in a FolderListModel as { filePath, fileName }, so the two built-in folders
    // can share one strip.
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

    component SectionTitle: Text {
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
    }

    // Title, with a button to open your folder (to add pictures).
    Item {
        width: root.contentWidth
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

    SectionTitle {
        text: yours.count > 0 ? "Your pictures" : "Your pictures: none yet. Put some in ~/Pictures/Wallpapers (Open folder)."
    }

    ListView {
        visible: yours.count > 0
        width: root.contentWidth
        height: root.thumbHeight
        orientation: ListView.Horizontal
        spacing: Theme.spacing.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.files(yours) // re-read when the folder changes (files() reads its count)
        delegate: Thumbnail {}

        Accessible.role: Accessible.List
        Accessible.name: "Your pictures"
    }

    SectionTitle {
        topPadding: Theme.spacing.xs
        visible: hyprland.count + cachyos.count > 0
        text: "Built-in (Hyprland and CachyOS)"
    }

    // Two rows, filled top to bottom, then sideways.
    GridView {
        visible: hyprland.count + cachyos.count > 0
        width: root.contentWidth
        height: cellHeight * 2
        flow: GridView.FlowTopToBottom
        cellWidth: root.thumbWidth + Theme.spacing.s
        cellHeight: root.thumbHeight + Theme.spacing.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.files(hyprland).concat(root.files(cachyos))
        delegate: Thumbnail {}

        Accessible.role: Accessible.List
        Accessible.name: "Built-in wallpapers"
    }
}
