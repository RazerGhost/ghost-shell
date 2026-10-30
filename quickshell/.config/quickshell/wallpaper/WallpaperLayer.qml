import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import qs.customize
import qs.services
import qs.theme

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
        readonly property bool playing: Wallpaper.isVideo && !GameMode.on && !UPower.onBattery && !Session.locked
                                        && (monitor?.activeWorkspace?.toplevels.values.length ?? 1) === 0
        // Drawn as a card while the desktop editor is open on this screen (customize/Editing.qml).
        readonly property bool carded: Editing.cardScreen === modelData.name

        screen: modelData
        // Until a wallpaper is chosen, Hyprland's default shows instead.
        visible: Wallpaper.path !== ""

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: carded ? Colors.m3surface : "black"

        WlrLayershell.namespace: "qs-wallpaper"
        WlrLayershell.layer: WlrLayer.Background

        ClippingRectangle {
            id: stage

            x: window.carded ? Editing.card.x : 0
            y: window.carded ? Editing.card.y : 0
            width: window.carded ? Editing.card.width : window.width
            height: window.carded ? Editing.card.height : window.height
            radius: window.carded ? Theme.radius.l * 1.5 : 0
            color: "black"

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
                source: !Wallpaper.stillPath ? ""
                      : "file://" + Wallpaper.stillPath + (Wallpaper.isVideo ? "#" + encodeURIComponent(Wallpaper.path) : "")
                cache: !Wallpaper.isVideo
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
                active: Wallpaper.isVideo

                sourceComponent: Video {
                    id: video
                    source: "file://" + Wallpaper.path
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
