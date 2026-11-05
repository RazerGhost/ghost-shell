import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.theme

// The sound outputs (speakers, headphones) or the microphones as rows to pick from, the chosen
// one ticked: on the Sound page and in the chooser under quick settings' volume slider.
// Picking one makes it the default (WirePlumber remembers it).
Column {
    id: root

    property bool outputs: true

    // PipeWire only fills in a node's name for display while something tracks it.
    PwObjectTracker {
        objects: root.outputs ? Audio.outputs : Audio.inputs
    }

    Repeater {
        model: root.outputs ? Audio.outputs : Audio.inputs

        ListRow {
            required property PwNode modelData
            readonly property bool chosen: modelData === (root.outputs ? Audio.sink : Audio.source)

            width: root.width
            icon: root.outputs ? Audio.deviceIcon(modelData) : "mic"
            title: Audio.deviceName(modelData)
            highlighted: chosen
            trailingIcon: chosen ? "check" : ""
            onActivated: {
                if (root.outputs)
                    Pipewire.preferredDefaultAudioSink = modelData;
                else
                    Pipewire.preferredDefaultAudioSource = modelData;
            }

            Accessible.role: Accessible.RadioButton
            Accessible.checkable: true
            Accessible.checked: chosen
        }
    }
}
