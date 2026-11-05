import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.theme
import qs.widgets
import "../services/AudioDevices.js" as AudioDevices

// Sound: the equalizer, a preset or five bands by hand for the output that's playing (each
// speaker or pair of headphones keeps its own; services/Equalizer.qml), heard at once; and sound
// events, which of the shell's short sounds play (services/Sounds.qml).
Column {
    spacing: Theme.spacing.l

    SettingGroup {
        visible: !Equalizer.running

        SettingRow {
            title: "The equalizer isn't running"
            subtitle: "Start it with: systemctl --user enable --now filter-chain.service"
        }
    }

    SettingGroup {
        visible: Equalizer.running
        title: "For " + (Equalizer.device ? Audio.deviceName(Equalizer.device) : "no output")

        SettingRow {
            title: "Preset"
            subtitle: "Each speaker or pair of headphones keeps its own"

            Stepper {
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

        Repeater {
            model: Equalizer.bands

            SettingRow {
                id: band

                required property var modelData
                required property int index

                title: modelData.label
                subtitle: modelData.frequency

                Stepper {
                    label: band.title
                    values: Array.from({ length: Equalizer.limit * 2 + 1 }, (_, i) => i - Equalizer.limit)
                    value: Equalizer.gains[band.index]
                    format: v => (v > 0 ? "+" : "") + v + " dB"
                    onPicked: v => Equalizer.setBand(band.index, v)
                }
            }
        }
    }

    // Which plugged-in or connected devices take the sound, like headphones on a phone. Only
    // the ones that can (USB and Bluetooth; AudioDevices.deviceKey), as they're connected now.
    SettingGroup {
        id: takeover

        readonly property var devices: Audio.outputs.filter(node => AudioDevices.deviceKey(node.name) !== "")

        visible: devices.length > 0
        title: "When a device connects"

        // Their names come from their properties, which PipeWire fills in only for tracked nodes.
        PwObjectTracker {
            objects: takeover.devices
        }

        Repeater {
            model: takeover.devices

            SettingRow {
                id: takeoverRow

                required property PwNode modelData
                readonly property string key: AudioDevices.deviceKey(modelData.name)

                title: Audio.deviceName(modelData)
                subtitle: "Takes the sound when it's plugged in or connects"

                Switch {
                    label: takeoverRow.title + " takes the sound when it connects"
                    checked: AudioDevices.mayTakeOver(takeoverRow.modelData.name, Settings.values.audioTakeover)
                    onToggled: Settings.values.audioTakeover = Object.assign({}, Settings.values.audioTakeover,
                                                                             { [takeoverRow.key]: !checked })
                }
            }
        }
    }

    SettingGroup {
        title: "Sound events"

        SettingRow {
            title: "Play sounds"
            subtitle: "Short sounds for the events below, quieter than other sound"

            Switch {
                label: "Play sounds"
                checked: Settings.values.soundEvents
                onToggled: Settings.values.soundEvents = !checked
            }
        }

        Repeater {
            // The charger and the battery warnings only where there's a battery.
            model: [
                { key: "soundNotifications", title: "Notifications", subtitle: "Not while Do Not Disturb is on" },
                { key: "soundDevices", title: Battery.present ? "Charger and USB" : "USB devices", subtitle: "Plugging in and out" },
                { key: "soundFeedback", title: "Volume and screenshots", subtitle: "A tick for the volume keys, a shutter for screenshots" },
                { key: "soundBattery", title: "Low battery", subtitle: "With the battery warnings" }
            ].filter(kind => kind.key !== "soundBattery" || Battery.present)

            SettingRow {
                id: eventRow

                required property var modelData

                title: modelData.title
                subtitle: modelData.subtitle
                enabled: Settings.values.soundEvents

                Switch {
                    label: eventRow.title
                    checked: Settings.values[eventRow.modelData.key]
                    onToggled: Settings.values[eventRow.modelData.key] = !checked
                }
            }
        }
    }
}
