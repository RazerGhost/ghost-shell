import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.services
import qs.theme
import "../services/FileUrl.js" as FileUrl

// Draws the chosen wallpaper (services/Wallpaper.qml) behind everything on every monitor.
// A new one fades in over the old one. A video (a live wallpaper) plays over its still frame,
// muted, only while it can be seen and it costs little: no window on the workspace, not in game
// mode, not on battery, not while locked; otherwise it stops on the frame it was at.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property ShellScreen modelData
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        readonly property bool playing: video !== "" && !GameMode.on && !UPower.onBattery && !Session.locked
                                        && (monitor?.activeWorkspace?.toplevels.values.length ?? 1) === 0
        // This screen's own picture, with one per screen ("" when it shows the main wallpaper,
        // which may be a live one).
        readonly property string own: { const p = Wallpaper.pathFor(modelData?.name ?? ""); return p !== Wallpaper.path ? p : ""; }
        readonly property string still: own !== "" ? Wallpaper.stillFor(own) : Wallpaper.stillPath
        // What plays here: its own video, else the main one's.
        readonly property string video: own !== "" ? (Wallpaper.isVideoPath(own) ? own : "") : (Wallpaper.isVideo ? Wallpaper.path : "")
        // Drawn as a card while the desktop editor is open on this screen (customize/Editing.qml).
        readonly property bool carded: Editing.cardScreen === modelData?.name // null while it's unplugged

        screen: modelData
        // Until a wallpaper is chosen, Hyprland's default shows instead (but an editor's card
        // and the color around it still show).
        visible: Wallpaper.path !== "" || carded

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: carded ? Colors.m3surface : "black"

        WlrLayershell.namespace: "qs-wallpaper"
        WlrLayershell.layer: WlrLayer.Background

        // The card's rounded shape, for the mask below.
        Rectangle {
            id: stageMask
            width: stage.width
            height: stage.height
            radius: Theme.radius.l * 1.5
            visible: false
            layer.enabled: window.carded
        }

        // The wallpaper's area. Rounded only while it's a card: through a mask, and only then,
        // since clipping costs a screen-sized texture (a ClippingRectangle always draws through
        // one), every frame of a live wallpaper.
        Item {
            id: stage

            x: window.carded ? Editing.card.x : 0
            y: window.carded ? Editing.card.y : 0
            width: window.carded ? Editing.card.width : window.width
            height: window.carded ? Editing.card.height : window.height
            layer.enabled: window.carded
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: stageMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Rectangle {
                anchors.fill: parent
                color: "black"
            }

            Behavior on x { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
            Behavior on y { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
            Behavior on width { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
            Behavior on height { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }

            // The previous wallpaper stays under the new one until the new one has faded in.
            Image {
                id: previous
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(window.width, window.height)
            }

            Image {
                id: current

                anchors.fill: parent
                // Every video's frame has the same name: the video's path after the # makes each a new
                // address, so the next video's frame loads (and isn't kept from the last one).
                source: !window.still ? ""
                      : FileUrl.of(window.still) + (Wallpaper.isVideo && window.own === "" ? "#" + encodeURIComponent(Wallpaper.path) : "")
                cache: !(Wallpaper.isVideo && window.own === "")
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Decode at the screen's size, not the picture's (a 6K photo would use ~100 MB).
                sourceSize: Qt.size(window.width, window.height)
                opacity: 0

                onStatusChanged: {
                    if (status === Image.Ready)
                        fadeIn.restart();
                }

                NumberAnimation {
                    id: fadeIn
                    target: current
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.anim.morph
                    onFinished: previous.source = current.source
                }
            }

            // The live wallpaper, only built while one is chosen.
            Loader {
                anchors.fill: parent
                active: window.video !== ""

                sourceComponent: Video {
                    id: video
                    source: FileUrl.of(window.video)
                    fillMode: VideoOutput.PreserveAspectCrop
                    loops: MediaPlayer.Infinite
                    muted: true
                    Component.onCompleted: {
                        if (window.playing)
                            play();
                    }
                    // Another video: a new source stops playing.
                    onSourceChanged: {
                        if (window.playing)
                            play();
                    }

                    Connections {
                        target: window

                        function onPlayingChanged(): void {
                            if (window.playing)
                                video.play();
                            else
                                video.pause();
                        }
                    }
                }
            }
        }
    }
}
