import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.theme

// The sound outputs (speakers, headphones) or the microphones as rows to pick from, the chosen
// one ticked: on the Sound page and in the chooser under quick settings' volume slider.
// Picking one makes it the default (WirePlumber remembers it). Past Theme.list.rows it scrolls,
// like the Wi-Fi and Bluetooth lists: a mixer like openxlr adds a dozen virtual outputs, which
// pushed the rest of the page off the island.
Flickable {
    id: root

    property bool outputs: true

    implicitHeight: Math.min(rows.implicitHeight, Theme.list.rows * Theme.list.rowHeight)
    contentHeight: rows.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // PipeWire only fills in a node's name for display while something tracks it.
    PwObjectTracker {
        objects: root.outputs ? Audio.outputs : Audio.inputs
    }

    Column {
        id: rows

        width: root.width

        Repeater {
            model: root.outputs ? Audio.outputs : Audio.inputs

            ListRow {
                required property PwNode modelData
                readonly property bool chosen: modelData === (root.outputs ? Audio.sink : Audio.source)

                width: rows.width
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
}
