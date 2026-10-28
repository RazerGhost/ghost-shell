import QtQuick
import qs.services
import qs.theme
import qs.widgets

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
            model: [
                { key: "soundNotifications", title: "Notifications", subtitle: "Not while Do Not Disturb is on" },
                { key: "soundDevices", title: "Charger and USB", subtitle: "Plugging in and out" },
                { key: "soundFeedback", title: "Volume and screenshots", subtitle: "A tick for the volume keys, a shutter for screenshots" },
                { key: "soundBattery", title: "Low battery", subtitle: "With the battery warnings" }
            ]

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
