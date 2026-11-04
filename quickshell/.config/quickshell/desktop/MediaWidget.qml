import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The media widget (medium), like iOS's Now Playing: the cover fills the card, darkened toward
// the bottom, with the track and artist and previous, play and next over it in white. Clicking
// outside the buttons brings up the player's window. Without a cover it's glass like the other
// widgets; without a player it says nothing plays, and play opens the music app last heard
// (Media.lastApp), when there is one.
WidgetSurface {
    id: widget

    readonly property MprisPlayer player: Media.player
    readonly property DesktopEntry app: player ? null : Media.lastApp
    // The cover is the card: everything over it turns light.
    readonly property bool onCover: art.status === Image.Ready
    readonly property color text: onCover ? Colors.onPicture : Colors.m3onSurface
    readonly property color subtext: onCover ? Colors.onPictureVariant : Colors.m3onSurfaceVariant

    // On the lock screen (desktop/WidgetStage.qml): only previous, play or pause, and next.
    // Opening the music app or bringing the player's window forward would act on the desktop
    // behind the lock.
    property bool locked: false

    function open(): void {
        if (app && !locked)
            Apps.launch(app);
    }

    medium: true

    // The cover over the whole card (the content sits inside the padding: out to its edges
    // again), fading in when it loads.
    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: -Theme.desktop.padding
        radius: Theme.desktop.radius
        color: "transparent"
        opacity: widget.onCover ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }

        Image {
            id: art
            anchors.fill: parent
            source: widget.player ? Media.cover(widget.player) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * 2
            Accessible.ignored: true
        }

        // Darker toward the bottom, where the buttons are; a little over the whole cover, so
        // the title reads on a bright one.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Colors.pictureShadeTop }
                GradientStop { position: 1; color: Colors.pictureShade }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !widget.locked
        cursorShape: widget.player || widget.app ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: widget.player ? Media.show() : widget.open()
    }

    // No cover (nothing playing, or a player without one): a music note where it would be.
    MaterialIcon {
        anchors.top: parent.top
        anchors.right: parent.right
        visible: !widget.onCover
        icon: "music_note"
        color: Colors.m3primary
        font.pixelSize: Theme.desktop.icon
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: widget.onCover ? 0 : Theme.desktop.icon + Theme.spacing.s
        anchors.top: parent.top
        spacing: 2

        Text {
            width: parent.width
            text: widget.player ? (widget.player.trackTitle || widget.player.identity || "") : "Nothing playing"
            color: widget.text
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.title
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: widget.player ? (widget.player.trackArtist ?? "") : widget.app ? "Play opens " + widget.app.name : ""
            color: widget.subtext
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            elide: Text.ElideRight
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: -Theme.spacing.s
        anchors.bottom: parent.bottom
        spacing: Theme.spacing.xs

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_previous"
            color: widget.text
            label: "Previous track"
            enabled: widget.player?.canGoPrevious ?? false
            onClicked: widget.player.previous()
        }

        // Play and pause in a filled circle, the main button: the accent on glass, white on a
        // cover.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.icon.normal * 2
            height: width
            radius: width / 2
            color: widget.onCover ? Colors.onPicture : Colors.m3primary

            IconButton {
                anchors.centerIn: parent
                icon: widget.player?.isPlaying ? "pause" : "play_arrow"
                color: widget.onCover ? Colors.onPictureButton : Colors.m3onPrimary
                label: widget.player ? (widget.player.isPlaying ? "Pause" : "Play") : widget.app ? "Open " + widget.app.name : "Play"
                enabled: widget.player ? widget.player.canTogglePlaying : widget.app !== null && !widget.locked
                onClicked: widget.player ? widget.player.togglePlaying() : widget.open()
            }
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_next"
            color: widget.text
            label: "Next track"
            enabled: widget.player?.canGoNext ?? false
            onClicked: widget.player.next()
        }
    }
}
