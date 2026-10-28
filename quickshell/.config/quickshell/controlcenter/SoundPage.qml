import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// Sound page of quick settings: the switch mutes the speakers; below it, where sound goes
// (speakers, headphones), which microphone records, and a volume slider for each app that's
// playing.
Column {
    id: root

    signal back()

    // Speakers and headphones (hardware outputs), microphones (hardware inputs), and the apps
    // that are playing sound (output streams).
    readonly property list<PwNode> outputs: devices(true)
    readonly property list<PwNode> inputs: devices(false)
    readonly property list<PwNode> apps: (Pipewire.nodes?.values ?? [])
        .filter(n => n.audio && n.isStream && !n.isSink)

    function devices(sink: bool): list<PwNode> {
        return (Pipewire.nodes?.values ?? []).filter(n => n.audio && !n.isStream && n.isSink === sink);
    }

    // The app's own name from its .desktop file ("Vesktop") when one matches, else PipeWire's.
    function appName(node: PwNode): string {
        const name = node.properties["application.name"] || node.description || node.name;
        return DesktopEntries.heuristicLookup(name)?.name || name;
    }

    spacing: Theme.spacing.s

    // PipeWire only fills in volume and app details for nodes something tracks.
    PwObjectTracker {
        objects: [...root.apps, ...root.outputs, ...root.inputs]
    }

    PageHeader {
        width: parent.width
        title: "Sound"
        checked: !Audio.muted
        onToggled: Audio.toggleMute()
        onBack: root.back()
    }

    component Heading: Text {
        leftPadding: Theme.spacing.m
        topPadding: Theme.spacing.xs
        color: Colors.m3primary
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        font.weight: Font.DemiBold
    }

    Heading {
        text: "Output"
    }

    Repeater {
        model: root.outputs

        ListRow {
            required property PwNode modelData
            readonly property bool chosen: modelData === Audio.sink

            width: root.width
            icon: Audio.deviceName(modelData).toLowerCase().includes("head") ? "headphones" : "speaker"
            title: Audio.deviceName(modelData)
            highlighted: chosen
            trailingIcon: chosen ? "check" : ""
            onActivated: Pipewire.preferredDefaultAudioSink = modelData

            Accessible.role: Accessible.RadioButton
            Accessible.checkable: true
            Accessible.checked: chosen
        }
    }

    Heading {
        visible: root.inputs.length > 1
        text: "Microphone"
    }

    // Only worth a choice when there's more than one.
    Repeater {
        model: root.inputs.length > 1 ? root.inputs : []

        ListRow {
            required property PwNode modelData
            readonly property bool chosen: modelData === Audio.source

            width: root.width
            icon: "mic"
            title: Audio.deviceName(modelData)
            highlighted: chosen
            trailingIcon: chosen ? "check" : ""
            onActivated: Pipewire.preferredDefaultAudioSource = modelData

            Accessible.role: Accessible.RadioButton
            Accessible.checkable: true
            Accessible.checked: chosen
        }
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
