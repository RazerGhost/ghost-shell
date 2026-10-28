import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The island's "live activity" while music plays: a small album cover and three bars that
// follow the sound coming out of the speakers (left channel, overall, right channel; everything
// that plays, which is mostly the music).
Row {
    id: root

    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spacing.s

    // Only measured while music plays.
    PwNodePeakMonitor {
        id: levels
        node: Audio.sink
        enabled: Media.playing
    }

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
                // Left, overall, right (a mono output shows the same level three times).
                readonly property real level: index === 1 || levels.peaks.length < 2 ? levels.peak
                                            : levels.peaks[index === 0 ? 0 : levels.peaks.length - 1]
                required property int index

                anchors.bottom: parent.bottom
                width: 3
                height: Math.max(width, parent.height * (Media.playing ? Math.min(1, level) : 0.2))
                radius: width / 2
                color: Colors.m3primary

                Behavior on height {
                    NumberAnimation { duration: Theme.media.barSmoothing; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
