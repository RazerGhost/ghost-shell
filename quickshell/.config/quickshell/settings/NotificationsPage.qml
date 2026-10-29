import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "../services/NotificationRules.js" as Rules
import "../services/Schedule.js" as Schedule

// Notifications: Do Not Disturb, on/off and an optional daily schedule (e.g. at night), and
// each app that has sent one: silent, pop up, or always pop up.
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

    SettingGroup {
        title: "Apps"
        visible: Object.keys(Settings.values.notificationApps).length > 0

        Repeater {
            model: Object.keys(Settings.values.notificationApps).sort((a, b) => a.localeCompare(b))

            SettingRow {
                id: appRow

                required property string modelData

                title: modelData
                subtitle: Rules.mode(Settings.values.notificationApps, modelData) === "silent" ? "Only in the notification list"
                        : Rules.mode(Settings.values.notificationApps, modelData) === "always" ? "Also during Do Not Disturb and game mode"
                        : ""

                Stepper {
                    label: "Notifications from " + appRow.modelData
                    values: Rules.modes
                    valueWidth: Theme.settings.stepperWide
                    value: Rules.mode(Settings.values.notificationApps, appRow.modelData)
                    format: v => Rules.labels[v]
                    onPicked: v => Settings.values.notificationApps = Rules.withMode(Settings.values.notificationApps, appRow.modelData, v)
                }
            }
        }
    }
}
