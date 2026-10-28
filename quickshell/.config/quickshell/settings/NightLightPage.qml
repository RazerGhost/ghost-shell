import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "../services/Schedule.js" as Schedule

// Night light: on/off, how warm, and an optional daily schedule.
Column {
    spacing: Theme.spacing.l

    SettingGroup {
        SettingRow {
            title: "Night light"
            subtitle: "Warmer colors, easier on the eyes in the evening"

            Switch {
                label: "Night light"
                checked: NightLight.on
                onToggled: NightLight.toggle()
            }
        }

        SettingRow {
            title: "Warmth"
            subtitle: "Lower is warmer"

            Stepper {
                label: "Warmth"
                values: Array.from({ length: 15 }, (_, i) => 2500 + i * 250)
                value: Settings.values.nightLightTemperature
                format: v => v + " K"
                onPicked: v => Settings.values.nightLightTemperature = v
            }
        }
    }

    SettingGroup {
        title: "Schedule"

        SettingRow {
            title: "Turn on automatically"
            subtitle: "Switching it by hand lasts until the next start or end time"

            Switch {
                label: "Night light schedule"
                checked: Settings.values.nightLightScheduled
                onToggled: Settings.values.nightLightScheduled = !checked
            }
        }

        SettingRow {
            title: "From"
            enabled: Settings.values.nightLightScheduled

            Stepper {
                label: "Night light from"
                values: Schedule.quarterHours
                wrap: true
                value: Settings.values.nightLightStart
                format: Schedule.format
                onPicked: v => Settings.values.nightLightStart = v
            }
        }

        SettingRow {
            title: "Until"
            enabled: Settings.values.nightLightScheduled

            Stepper {
                label: "Night light until"
                values: Schedule.quarterHours
                wrap: true
                value: Settings.values.nightLightEnd
                format: Schedule.format
                onPicked: v => Settings.values.nightLightEnd = v
            }
        }
    }
}
