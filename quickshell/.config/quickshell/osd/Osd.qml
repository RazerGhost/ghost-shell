import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// Popup for volume, mic mute and brightness changes: an icon and a level bar at the bottom
// of the focused monitor, hidden again a moment after the last change. Caps lock, the keyboard
// layout, the power mode, a new sound output and a VPN connecting show there too, as a label.
Scope {
    id: root

    property string icon
    property string label
    property real level: -1 // 0-1; -1 hides the level bar (mic mute has no level)
    property bool shown: false

    // PipeWire reports the starting volume and mute state shortly after the shell starts,
    // which looks like a change; ignore changes until this has fired.
    property bool ready: false
    // The output before the current one (PipeWire's default sink), to tell a switch from startup.
    property var lastSink: null

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

    Component.onCompleted: lastSink = Audio.sink

    Timer {
        id: hide
        // Settings' osdSeconds (1-5 s in Settings; a hand-edited file is kept within 0.5-10).
        interval: Math.min(10, Math.max(0.5, Number(Settings.values.osdSeconds) || 1.5)) * 1000
        onTriggered: root.shown = false
    }

    // Volume changes also come from outside the shell (keybinds, pavucontrol, apps), so
    // react to the values themselves instead of to the keys that change them.
    Connections {
        target: Audio

        // A new output brings its own volume and mute state: the output's name shows instead.
        function onVolumeChanged(): void {
            if (outputSwitched.running)
                return;
            if (root.ready)
                Sounds.play("feedback", "audio-volume-change");
            root.show(Audio.icon, "Volume", Audio.volume);
        }

        function onMutedChanged(): void {
            if (outputSwitched.running)
                return;
            root.show(Audio.icon, Audio.muted ? "Muted" : "Volume", Audio.volume);
        }

        function onMicMutedChanged(): void {
            root.show(Audio.micMuted ? "mic_off" : "mic", Audio.micMuted ? "Microphone muted" : "Microphone on", -1);
        }

        // An app starts recording (a call) while the microphone is muted.
        function onMutedWhileRecordingChanged(): void {
            if (Audio.mutedWhileRecording)
                root.show("mic_off", "Microphone is muted", -1);
        }

        // Headphones plugged in, a Bluetooth headset connected, or an output picked in the
        // Sound page. Not the first output PipeWire reports at startup.
        function onSinkChanged(): void {
            if (Audio.sink !== null && root.lastSink !== null && Audio.sink !== root.lastSink)
                outputSwitched.restart();
            if (Audio.sink !== null)
                root.lastSink = Audio.sink;
        }
    }

    // A new output's name fills in once PipeWire's tracker has its properties, and its volume
    // arrives about then too.
    Timer {
        id: outputSwitched
        interval: 500
        onTriggered: {
            if (Audio.sink)
                root.show(Audio.deviceIcon(Audio.sink), Audio.deviceName(Audio.sink), -1);
        }
    }

    Connections {
        target: NetworkExtras

        function onVpnSwitched(name: string, connected: bool): void {
            root.show(connected ? "vpn_key" : "vpn_key_off", (connected ? "Connected to " : "Disconnected from ") + name, -1);
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

    Connections {
        target: PowerProfiles

        function onProfileChanged(): void {
            const profile = PowerProfiles.profile;
            root.show(profile === PowerProfile.PowerSaver ? "eco" : profile === PowerProfile.Performance ? "speed" : "balance",
                      profile === PowerProfile.PowerSaver ? "Power saver" : profile === PowerProfile.Performance ? "Performance" : "Balanced",
                      -1);
        }
    }

    // The keyboard's layout and caps lock (services/Keyboard.qml).
    Connections {
        target: Keyboard

        function onLayoutSwitched(name: string): void {
            root.show("keyboard", name, -1);
        }

        function onCapsLockSwitched(on: bool): void {
            root.show("keyboard_capslock", on ? "Caps lock on" : "Caps lock off", -1);
        }
    }

    PanelWindow {
        // Follow the keyboard focus to whichever monitor the user is working on.
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        visible: root.shown

        // At the bottom (above the dock while it shows on this screen, closer to the edge while
        // it's hidden), or at the top just under the island (Settings' osdPosition).
        readonly property bool top: Settings.values.osdPosition === "top"
        anchors.bottom: !top
        anchors.top: top
        margins.bottom: DockState.shownOn !== "" && DockState.shownOn === screen?.name ? Theme.osd.gap : Theme.osd.gapLow
        margins.top: Theme.island.height + Theme.osd.below
        implicitWidth: Theme.osd.width
        implicitHeight: Theme.osd.height

        // Float over windows without pushing them aside, and let clicks through: an empty
        // mask means the surface takes no mouse input at all.
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        color: "transparent"

        WlrLayershell.namespace: "qs-osd"

        // Blur behind the card (ext-background-effect; see NOTES.md).
        BackgroundEffect.blurRegion: Region { item: surface; radius: surface.radius }

        WlrLayershell.layer: WlrLayer.Overlay

        Surface {
            id: surface

            anchors.fill: parent
            radius: Theme.radius.full

            Accessible.role: Accessible.Indicator
            Accessible.name: root.level < 0 ? root.label : root.label + " " + Math.round(root.level * 100) + "%"

            // A level bar fills the card; a label alone (caps lock, layout, power mode) sits in
            // the middle with its icon.
            Row {
                readonly property real fullWidth: parent.width - Theme.spacing.l * 2

                anchors.verticalCenter: parent.verticalCenter
                x: root.level >= 0 ? Theme.spacing.l : (parent.width - width) / 2
                width: root.level >= 0 ? fullWidth : implicitWidth
                height: parent.height
                spacing: Theme.spacing.m

                // From a level bar to a label (volume, then the output's name) without a jump.
                Behavior on x {
                    NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.easing }
                }
                Behavior on width {
                    NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.easing }
                }

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
                    // Long layout names ("English (US, intl., with dead keys)") end in "…".
                    width: Math.min(implicitWidth, parent.fullWidth - glyph.width - parent.spacing)
                    elide: Text.ElideRight
                    text: root.label
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }
        }
    }
}
