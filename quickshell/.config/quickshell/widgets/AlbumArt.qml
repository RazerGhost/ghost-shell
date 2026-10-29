import QtQuick
import Quickshell.Widgets
import qs.theme

// A track's cover, rounded, with a music note while there's none (or it's still loading): the
// island's live activity, the hover player and the media menu. Set its width and height.
ClippingRectangle {
    id: root

    property string source // Media.cover(player)
    property int iconSize: Theme.icon.normal

    color: Colors.m3surfaceContainerHighest
    radius: Theme.radius.m

    MaterialIcon {
        anchors.centerIn: parent
        visible: art.status !== Image.Ready
        icon: "music_note"
        color: Colors.m3onSurfaceVariant
        font.pixelSize: root.iconSize
    }

    Image {
        id: art
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Decoded at twice the shown size (sharp on HiDPI), not the full-size picture.
        sourceSize.width: width * 2
        Accessible.ignored: true
    }
}
