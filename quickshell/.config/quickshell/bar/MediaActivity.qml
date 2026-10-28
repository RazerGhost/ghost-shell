import QtQuick
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The island's "live activity" while music plays: a small album cover and three bars that
// bounce while playing. The bars are an effect, not the real audio levels.
Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.s

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

    Row {
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.media.barHeight
        spacing: 2

        Repeater {
            model: 3

            Rectangle {
                id: bar

                // A new random height every tick while playing; a short stub when paused.
                property real level: 0.3

                anchors.bottom: parent.bottom
                width: 3
                height: Math.max(width, parent.height * (Media.playing ? level : 0.2))
                radius: width / 2
                color: Colors.m3primary

                Behavior on height {
                    NumberAnimation { duration: Theme.media.barTick; easing.type: Easing.InOutSine }
                }

                Timer {
                    interval: Theme.media.barTick
                    running: Media.playing
                    repeat: true
                    onTriggered: bar.level = 0.25 + Math.random() * 0.75
                }
            }
        }
    }
}
