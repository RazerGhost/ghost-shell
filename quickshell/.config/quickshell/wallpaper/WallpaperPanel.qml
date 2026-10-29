import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The wallpaper picker's contents (WallpaperPicker.qml is the strip): one row of
// pictures, scrolling sideways (the mouse wheel too). Your pictures from ~/Pictures/Wallpapers
// come first, then the built-in ones that come with Hyprland and CachyOS (from their packages,
// so they're not copied anywhere). Click one to use it; the colors follow the picture.
Column {
    id: root

    // The strip is open (WallpaperPicker.qml).
    property bool active
    // Thumbnails only load once the picker has been opened: the built-in pictures are large
    // (up to 5K), and decoding them all at login would keep the CPU busy for nothing.
    property bool opened: false

    readonly property real contentWidth: width - leftPadding - rightPadding
    readonly property real thumbHeight: Theme.wallpaper.thumbHeight
    readonly property real thumbWidth: thumbHeight * 16 / 9

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.s

    onActiveChanged: {
        if (active) {
            opened = true;
            Wallpaper.rescan();
            // Start on the current wallpaper.
            list.currentIndex = Math.max(0, Wallpaper.pictures.findIndex(p => p.filePath === Wallpaper.path));
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
        }
    }

    // From the strip (WallpaperPicker.qml): Left/Right move the selection, Enter uses it.
    function handleKey(event: var): void {
        switch (event.key) {
        case Qt.Key_Left:
            list.decrementCurrentIndex();
            break;
        case Qt.Key_Right:
            list.incrementCurrentIndex();
            break;
        case Qt.Key_Home:
            list.currentIndex = 0;
            break;
        case Qt.Key_End:
            list.currentIndex = list.count - 1;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (list.currentItem)
                Wallpaper.set(list.currentItem.filePath);
            break;
        default:
            return;
        }
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
        event.accepted = true;
    }

    // One picture in the grid. The current wallpaper gets an accent outline, the selected one
    // (pointer or arrow keys) a light one.
    component Thumbnail: MouseArea {
        id: cell

        required property var modelData
        required property int index
        readonly property string filePath: modelData.filePath
        readonly property string fileName: modelData.fileName
        readonly property bool current: filePath === Wallpaper.path

        width: root.thumbWidth
        height: root.thumbHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: list.currentIndex = index
        onClicked: Wallpaper.set(filePath)

        Accessible.role: Accessible.ListItem
        Accessible.name: fileName + (current ? ", current wallpaper" : "")
        Accessible.selected: ListView.isCurrentItem
        Accessible.onPressAction: Wallpaper.set(filePath)

        ClippingRectangle {
            anchors.fill: parent
            radius: Theme.radius.m
            color: Colors.m3surfaceContainerHigh

            Image {
                anchors.fill: parent
                // A video shows its thumbnail (services/wallpapers.sh made it).
                source: !root.opened ? "" : "file://" + (cell.modelData.video ? cell.modelData.thumb : cell.filePath)
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
            border.width: cell.current ? Theme.outline.strong : cell.ListView.isCurrentItem ? Theme.outline.normal : 0
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
            text: "Wallpapers" + (Wallpaper.ownCount === 0
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
            onClicked: Apps.run(["sh", "-c", 'mkdir -p "$1" && exec xdg-open "$1"', "sh", Wallpaper.folder], "xdg-open", "")
        }
    }

    ListView {
        id: list

        width: root.contentWidth
        height: root.thumbHeight
        orientation: ListView.Horizontal
        spacing: Theme.spacing.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Wallpaper.pictures
        delegate: Thumbnail {}

        Accessible.role: Accessible.List
        Accessible.name: "Wallpapers"
    }
}
