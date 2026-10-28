import QtQuick
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The island's "live activity" while music plays: the album cover, in the time's place.
Row {
    anchors.verticalCenter: parent.verticalCenter

    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.media.activityArt
        height: Theme.media.activityArt
        radius: Theme.radius.s
        color: Colors.m3surfaceContainerHighest

        MaterialIcon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            icon: "music_note"
            font.pixelSize: Theme.icon.small
        }

        Image {
            id: art
            anchors.fill: parent
            source: Media.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * 2 // decode small: this is a 22px thumbnail
            Accessible.ignored: true
        }
    }
}
