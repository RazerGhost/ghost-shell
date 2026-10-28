import QtQuick
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets
import "TrackTime.js" as TrackTime

// The media menu, opened by clicking the island's live activity: a large cover, the track,
// a progress bar you can click or drag to seek, and the controls.
Column {
    id: root

    readonly property var player: Media.player
    readonly property bool hasLength: (player?.lengthSupported ?? false) && player.length > 0
    // While dragging, the bar follows the pointer instead of the player.
    property real dragFraction: -1

    padding: Theme.spacing.l
    topPadding: Theme.spacing.s
    spacing: Theme.spacing.m

    // MPRIS doesn't announce position changes while playing; Quickshell recomputes the
    // position when positionChanged is emitted, so tick once a second while it's on screen.
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && Media.playing
        onTriggered: root.player.positionChanged()
    }

    ClippingRectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.media.menuArt
        height: Theme.media.menuArt
        radius: Theme.radius.l
        color: Colors.m3surfaceContainerHighest

        MaterialIcon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            icon: "music_note"
            color: Colors.m3onSurfaceVariant
            font.pixelSize: Theme.icon.launcher
        }

        Image {
            id: art
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * 2
            Accessible.ignored: true
        }
    }

    Column {
        width: parent.width - root.leftPadding - root.rightPadding

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.player?.trackTitle || root.player?.identity || "Nothing playing"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            horizontalAlignment: Text.AlignHCenter
            text: [root.player?.trackArtist, root.player?.trackAlbum].filter(s => s).join(" · ")
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            elide: Text.ElideRight
        }
    }

    // Progress: click or drag to seek (when the player allows it).
    Column {
        visible: root.hasLength
        width: parent.width - root.leftPadding - root.rightPadding
        spacing: Theme.spacing.xs

        Item {
            id: track

            readonly property real fraction: root.dragFraction >= 0 ? root.dragFraction
                                            : root.hasLength ? Math.min(1, root.player.position / root.player.length)
                                            : 0

            width: parent.width
            height: Theme.spacing.m // taller than the bar, so it's easy to grab

            Accessible.role: Accessible.Slider
            Accessible.name: "Position " + TrackTime.format(root.player?.position ?? 0)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Theme.spacing.xs
                radius: height / 2
                color: Colors.m3surfaceContainerHighest

                Rectangle {
                    width: parent.width * track.fraction
                    height: parent.height
                    radius: height / 2
                    color: Colors.m3primary
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                function fractionAt(x: real): real {
                    return Math.max(0, Math.min(1, x / width));
                }

                onPressed: mouse => root.dragFraction = fractionAt(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        root.dragFraction = fractionAt(mouse.x);
                }
                onReleased: {
                    root.player.position = root.dragFraction * root.player.length;
                    root.dragFraction = -1;
                }
            }
        }

        Item {
            width: parent.width
            height: elapsed.implicitHeight

            Text {
                id: elapsed
                text: TrackTime.format(track.fraction * (root.player?.length ?? 0))
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                font.features: { "tnum": 1 }
            }

            Text {
                anchors.right: parent.right
                text: TrackTime.format(root.player?.length ?? 0)
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
                font.features: { "tnum": 1 }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacing.m

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_previous"
            label: "Previous track"
            iconSize: Theme.icon.osd
            enabled: root.player?.canGoPrevious ?? false
            opacity: enabled ? 1 : 0.35
            onClicked: root.player.previous()
        }

        // Play/pause in a filled circle, the main control.
        Rectangle {
            width: Theme.tile.height
            height: width
            radius: width / 2
            color: Colors.m3primary

            IconButton {
                anchors.centerIn: parent
                icon: root.player?.isPlaying ? "pause" : "play_arrow"
                label: root.player?.isPlaying ? "Pause" : "Play"
                color: Colors.m3onPrimary
                iconSize: Theme.icon.launcher
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_next"
            label: "Next track"
            iconSize: Theme.icon.osd
            enabled: root.player?.canGoNext ?? false
            opacity: enabled ? 1 : 0.35
            onClicked: root.player.next()
        }
    }
}
