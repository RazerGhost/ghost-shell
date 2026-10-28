import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The island's "live activity" while music plays: the album cover, in the time's place.
Row {
    anchors.verticalCenter: parent.verticalCenter

    AlbumArt {
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.media.activityArt
        height: Theme.media.activityArt
        radius: Theme.radius.s
        iconSize: Theme.icon.small
        source: Media.player?.trackArtUrl ?? ""
    }
}
