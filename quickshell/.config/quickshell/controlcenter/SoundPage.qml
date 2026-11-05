import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// Sound page of quick settings: the switch mutes the speakers; below it, where sound goes
// (speakers, headphones), the equalizer's preset for it, which microphone records, and a volume
// slider for each app that's playing.
Column {
    id: root

    signal back()

    // The apps that are playing sound (output streams; not the equalizer's own, see
    // Audio.outputs). The outputs and microphones are Audio's.
    readonly property list<PwNode> apps: (Pipewire.nodes?.values ?? [])
        .filter(n => n.audio && n.isStream && !n.isSink && !n.name.startsWith("ghost-equalizer"))

    // The app's own name from its .desktop file ("Vesktop") when one matches, else PipeWire's.
    function appName(node: PwNode): string {
        const name = node.properties["application.name"] || node.description || node.name;
        return DesktopEntries.heuristicLookup(name)?.name || name;
    }

    spacing: Theme.spacing.s

    // PipeWire only fills in volume and app details for nodes something tracks.
    PwObjectTracker {
        objects: [...root.apps, ...Audio.outputs, ...Audio.inputs]
    }

    PageHeader {
        width: parent.width
        title: "Sound"
        checked: !Audio.muted
        onToggled: Audio.toggleMute()
        onBack: root.back()
    }

    component Heading: SectionHeading {
        leftPadding: Theme.spacing.m
        topPadding: Theme.spacing.xs
    }

    Heading {
        text: "Output"
    }

    DeviceList {
        width: root.width
        outputs: true
    }

    // The chosen output's preset; the bands themselves are in Settings -> Sound.
    Item {
        visible: Equalizer.running
        width: root.width
        implicitHeight: Theme.list.rowHeight

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.m
            anchors.verticalCenter: parent.verticalCenter
            text: "Equalizer"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }

        Stepper {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            label: "Equalizer preset"
            valueWidth: Theme.settings.stepperWide
            // "Custom" (bands set by hand) only shows while it's the current one.
            values: (Equalizer.preset === "Custom" ? ["Custom"] : []).concat(Equalizer.presets.map(p => p.name))
            value: Equalizer.preset
            onPicked: v => {
                const preset = Equalizer.presets.find(p => p.name === v);
                if (preset)
                    Equalizer.setGains(preset.gains);
            }
        }
    }

    Heading {
        visible: Audio.inputs.length > 1
        text: "Microphone"
    }

    // Only worth a choice when there's more than one.
    DeviceList {
        width: root.width
        visible: Audio.inputs.length > 1
        outputs: false
    }

    Heading {
        text: "Apps"
    }

    Text {
        visible: root.apps.length === 0
        width: parent.width
        leftPadding: Theme.spacing.m
        bottomPadding: Theme.spacing.s
        text: "No app is playing sound"
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
    }

    // One per app: its icon and name, and its own volume.
    Repeater {
        model: root.apps

        Column {
            id: app

            required property PwNode modelData

            width: root.width
            spacing: Theme.spacing.xs

            Row {
                leftPadding: Theme.spacing.m
                spacing: Theme.spacing.s

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: Theme.icon.small
                    source: Quickshell.iconPath(app.modelData.properties["application.icon-name"]
                                                || DesktopEntries.heuristicLookup(root.appName(app.modelData))?.icon
                                                || "application-x-executable", "application-x-executable")
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.appName(app.modelData)
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }
            }

            LevelSlider {
                width: parent.width
                value: app.modelData.audio.volume
                icon: app.modelData.audio.muted ? "volume_off" : "volume_up"
                label: root.appName(app.modelData) + " volume"
                onMoved: value => app.modelData.audio.volume = value
            }
        }
    }
}
