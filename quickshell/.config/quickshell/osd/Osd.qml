import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import "Keyboard.js" as Keyboard

// Popup for volume, mic mute and brightness changes: an icon and a level bar at the bottom
// of the focused monitor, hidden again a moment after the last change. Caps lock, the keyboard
// layout and the power mode show there too, as a label.
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
            if (root.ready)
                Sounds.play("feedback", "audio-volume-change");
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

    Connections {
        target: PowerProfiles

        function onProfileChanged(): void {
            const profile = PowerProfiles.profile;
            root.show(profile === PowerProfile.PowerSaver ? "eco" : profile === PowerProfile.Performance ? "speed" : "balance",
                      profile === PowerProfile.PowerSaver ? "Power saver" : profile === PowerProfile.Performance ? "Performance" : "Balanced",
                      -1);
        }
    }

    // Hyprland sends activelayout for every keyboard (virtual ones too, like wtype's for the emoji
    // picker), and again for the same layout: only the main keyboard's, and only a new name, shows.
    // Both are read from Hyprland at start (it sends no event then), so the first switch shows.
    property string layout: ""
    property string mainKeyboard: ""

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name !== "activelayout")
                return;
            const active = Keyboard.activeLayout(event.data);
            if (!active || active.keyboard !== root.mainKeyboard || active.layout === root.layout)
                return;
            root.layout = active.layout;
            root.show("keyboard", active.layout, -1);
        }
    }

    // The main keyboard's name and layout, once at start (Hyprland sends no activelayout then).
    Process {
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const main = Keyboard.mainKeyboard(text);
                if (main) {
                    root.mainKeyboard = main.name;
                    root.layout = main.layout;
                }
            }
        }
    }

    // Caps lock sends no event, and Hyprland doesn't run a bind on the key (tried: a release bind
    // that leaves the key alone never fired). Its light does follow it: the keyboard's
    // `::capslock` LED in sysfs, read in-process 4 times a second (sysfs files send no change
    // events, like the backlight's).
    property string capsLed: ""
    property string capsState: ""

    Process {
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null | head -n 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.capsLed = text.trim()
        }
    }

    FileView {
        id: capsFile
        path: root.capsLed !== "" ? root.capsLed + "/brightness" : ""
        blockLoading: true // read right away in the timer
    }

    Timer {
        interval: 250
        running: root.capsLed !== ""
        repeat: true
        onTriggered: {
            capsFile.reload();
            const state = capsFile.text().trim();
            if (state === "" || state === root.capsState)
                return;
            const first = root.capsState === "";
            root.capsState = state;
            if (!first)
                root.show("keyboard_capslock", state !== "0" ? "Caps lock on" : "Caps lock off", -1);
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

        // Blur behind the card (ext-background-effect; see NOTES.md).
        BackgroundEffect.blurRegion: Region { item: surface; radius: surface.radius }

        WlrLayershell.layer: WlrLayer.Overlay

        Surface {
            id: surface

            anchors.fill: parent
            radius: Theme.radius.full

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
                    // Long layout names ("English (US, intl., with dead keys)") end in "…".
                    width: parent.width - glyph.width - parent.spacing
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
