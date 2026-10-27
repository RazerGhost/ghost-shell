import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.theme
import qs.widgets

// Now playing, from any MPRIS player (Spotify, Zen, mpv...): cover, title, artist and
// previous / play-pause / next. Hidden when nothing is playing or paused.
Rectangle {
    id: root

    // The player that's playing, otherwise the first one (e.g. paused music).
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying)
                                          ?? Mpris.players.values[0] ?? null

    visible: player !== null
    implicitHeight: Theme.tile.height + Theme.spacing.m * 2
    radius: Theme.radius.l
    color: Colors.m3surfaceContainerHighest

    ClippingRectangle {
        id: cover

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.m
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.tile.height
        height: Theme.tile.height
        radius: Theme.radius.m
        color: Colors.m3surfaceContainerHigh

        MaterialIcon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            icon: "music_note"
            color: Colors.m3onSurfaceVariant
        }

        Image {
            id: art
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            Accessible.ignored: true
        }
    }

    Column {
        anchors.left: cover.right
        anchors.right: controls.left
        anchors.leftMargin: Theme.spacing.m
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.player?.trackTitle || root.player?.identity || ""
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.player?.trackArtist ?? ""
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }

    Row {
        id: controls

        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.s
        anchors.verticalCenter: parent.verticalCenter

        IconButton {
            icon: "skip_previous"
            label: "Previous track"
            visible: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }

        IconButton {
            icon: root.player?.isPlaying ? "pause" : "play_arrow"
            label: root.player?.isPlaying ? "Pause" : "Play"
            visible: root.player?.canTogglePlaying ?? false
            onClicked: root.player.togglePlaying()
        }

        IconButton {
            icon: "skip_next"
            label: "Next track"
            visible: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }
}
