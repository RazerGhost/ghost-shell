import QtQuick
import Quickshell.Services.Mpris
import qs.services
import qs.theme
import qs.widgets

// Compact now playing: cover, title, artist and previous / play-pause / next. The island
// shows it when you hover the live activity. Hidden when there's no player.
Rectangle {
    id: root

    readonly property MprisPlayer player: Media.player

    // Clicked outside the buttons.
    signal activated()

    visible: player !== null
    implicitHeight: Theme.tile.height + Theme.spacing.m * 2
    radius: Theme.radius.l
    color: Colors.m3surfaceContainerHighest

    // Under everything else, so the buttons keep their own clicks.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    Accessible.role: Accessible.Button
    Accessible.name: "Open media: " + (player?.trackTitle ?? "")
    Accessible.onPressAction: root.activated()

    AlbumArt {
        id: cover

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.m
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.tile.height
        height: Theme.tile.height
        color: Colors.m3surfaceContainerHigh
        source: Media.cover(root.player)
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
