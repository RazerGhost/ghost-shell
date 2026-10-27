import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// Popup for volume, mic mute and brightness changes: an icon and a level bar at the bottom
// of the focused monitor, hidden again a moment after the last change.
Scope {
    id: root

    property string icon
    property string label
    property real level: -1 // 0-1; -1 hides the level bar (mic mute has no level)
    property bool shown: false

    // PipeWire reports the starting volume and mute state shortly after the shell starts,
    // which looks like a change; ignore changes until this has fired.
    property bool ready: false

    function show(icon: string, label: string, level: real): void {
        if (!ready)
            return;
        root.icon = icon;
        root.label = label;
        root.level = level;
        shown = true;
        hide.restart();
    }

    Timer {
        interval: 1000
        running: true
        onTriggered: root.ready = true
    }

    Timer {
        id: hide
        interval: Theme.osd.timeout
        onTriggered: root.shown = false
    }

    // Volume changes also come from outside the shell (keybinds, pavucontrol, apps), so
    // react to the values themselves instead of to the keys that change them.
    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.show(Audio.icon, "Volume", Audio.volume);
        }

        function onMutedChanged(): void {
            root.show(Audio.icon, Audio.muted ? "Muted" : "Volume", Audio.volume);
        }

        function onMicMutedChanged(): void {
            root.show(Audio.micMuted ? "mic_off" : "mic", Audio.micMuted ? "Microphone muted" : "Microphone on", -1);
        }
    }

    Connections {
        target: Brightness

        function onChanged(): void {
            const level = Brightness.level;
            root.show(level < 0.34 ? "brightness_low" : level < 0.67 ? "brightness_medium" : "brightness_high",
                      "Brightness", level);
        }
    }

    PanelWindow {
        // Follow the keyboard focus to whichever monitor the user is working on.
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        visible: root.shown

        anchors.bottom: true
        margins.bottom: Theme.osd.gap
        implicitWidth: Theme.osd.width
        implicitHeight: Theme.osd.height

        // Float over windows without pushing them aside, and let clicks through: an empty
        // mask means the surface takes no mouse input at all.
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        color: "transparent"

        WlrLayershell.namespace: "qs-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.full
            color: Qt.rgba(Colors.m3surfaceContainer.r, Colors.m3surfaceContainer.g, Colors.m3surfaceContainer.b, Theme.bar.opacity)

            Accessible.role: Accessible.Indicator
            Accessible.name: root.level < 0 ? root.label : root.label + " " + Math.round(root.level * 100) + "%"

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.l
                anchors.rightMargin: Theme.spacing.l
                spacing: Theme.spacing.m

                MaterialIcon {
                    id: glyph
                    anchors.verticalCenter: parent.verticalCenter
                    icon: root.icon
                    font.pixelSize: Theme.icon.osd
                }

                // Level bar, or the label when there's no level to show.
                Rectangle {
                    id: track
                    visible: root.level >= 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - glyph.width - percent.width - parent.spacing * 2
                    height: Theme.osd.track
                    radius: Theme.radius.full
                    color: Colors.m3surfaceContainerHighest

                    Rectangle {
                        width: track.width * Math.max(0, Math.min(1, root.level))
                        height: parent.height
                        radius: Theme.radius.full
                        color: Colors.m3primary

                        Behavior on width {
                            NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.easing }
                        }
                    }
                }

                Text {
                    id: percent
                    visible: root.level >= 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.spacing.l * 2 // fixed, so the bar doesn't jump between 9% and 10%
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(root.level * 100)
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    font.features: { "tnum": 1 } // tabular digits: every digit the same width
                }

                Text {
                    visible: root.level < 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.label
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }
        }
    }
}
