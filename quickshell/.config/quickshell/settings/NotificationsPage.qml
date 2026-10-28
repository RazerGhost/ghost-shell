import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "../services/Schedule.js" as Schedule

// Notifications: Do Not Disturb, on/off and an optional daily schedule (e.g. at night).
Column {
    spacing: Theme.spacing.l

    SettingGroup {
        SettingRow {
            title: "Do Not Disturb"
            subtitle: "Only critical notifications pop up; the others still go to the notification list"

            Switch {
                label: "Do Not Disturb"
                checked: Notifications.doNotDisturb
                onToggled: Notifications.doNotDisturb = !checked
            }
        }
    }

    SettingGroup {
        title: "Schedule"

        SettingRow {
            title: "Turn on automatically"
            subtitle: "Switching it by hand lasts until the next start or end time"

            Switch {
                label: "Do Not Disturb schedule"
                checked: Settings.values.dndScheduled
                onToggled: Settings.values.dndScheduled = !checked
            }
        }

        SettingRow {
            title: "From"
            enabled: Settings.values.dndScheduled

            Stepper {
                label: "Do Not Disturb from"
                values: Schedule.quarterHours
                wrap: true
                value: Settings.values.dndStart
                format: Schedule.format
                onPicked: v => Settings.values.dndStart = v
            }
        }

        SettingRow {
            title: "Until"
            enabled: Settings.values.dndScheduled

            Stepper {
                label: "Do Not Disturb until"
                values: Schedule.quarterHours
                wrap: true
                value: Settings.values.dndEnd
                format: Schedule.format
                onPicked: v => Settings.values.dndEnd = v
            }
        }
    }
}
