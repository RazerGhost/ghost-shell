import QtQuick
import Quickshell.Services.Mpris
import qs.services
import qs.theme
import qs.widgets

// The media widget (medium): the cover, the track and artist, and previous, play and next.
// Clicking outside the buttons brings up the player's window. Without a player (the desktop
// editor's preview) it says nothing plays.
WidgetSurface {
    id: widget

    readonly property MprisPlayer player: Media.player

    medium: true

    MouseArea {
        anchors.fill: parent
        cursorShape: widget.player ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: Media.show()
    }

    AlbumArt {
        id: cover
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.desktop.cover
        height: width
        radius: Theme.radius.l
        color: Colors.m3surfaceContainerHigh
        iconSize: Theme.icon.normal * 1.6
        source: Media.cover(widget.player)
    }

    Column {
        anchors.left: cover.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.desktop.padding
        anchors.top: cover.top
        spacing: 2

        Text {
            width: parent.width
            text: widget.player ? (widget.player.trackTitle || widget.player.identity || "") : "Nothing playing"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: widget.player?.trackArtist ?? ""
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            elide: Text.ElideRight
        }
    }

    Row {
        anchors.left: cover.right
        anchors.leftMargin: Theme.desktop.padding - Theme.spacing.s
        anchors.bottom: cover.bottom
        spacing: Theme.spacing.xs

        IconButton {
            icon: "skip_previous"
            label: "Previous track"
            enabled: widget.player?.canGoPrevious ?? false
            onClicked: widget.player.previous()
        }

        // Play and pause in a filled circle, the main button.
        Rectangle {
            width: Theme.icon.normal * 2
            height: width
            radius: width / 2
            color: Colors.m3primary

            IconButton {
                anchors.centerIn: parent
                icon: widget.player?.isPlaying ? "pause" : "play_arrow"
                color: Colors.m3onPrimary
                label: widget.player?.isPlaying ? "Pause" : "Play"
                enabled: widget.player?.canTogglePlaying ?? false
                onClicked: widget.player.togglePlaying()
            }
        }

        IconButton {
            icon: "skip_next"
            label: "Next track"
            enabled: widget.player?.canGoNext ?? false
            onClicked: widget.player.next()
        }
    }
}
