import QtQuick
import qs.services
import qs.widgets
import "../services/Schedule.js" as Schedule

// A daily schedule for something that turns on and off (night light, Do Not Disturb): a switch
// and the start and end times, settings `<prefix>Scheduled`, `<prefix>Start` and `<prefix>End`
// (services/Schedule.js switches at those times; switching by hand lasts until the next).
SettingGroup {
    id: root

    required property string prefix // "nightLight", "dnd"
    required property string what   // for screen readers: "Night light", "Do Not Disturb"

    readonly property bool scheduled: Settings.values[prefix + "Scheduled"]

    title: "Schedule"

    SettingRow {
        title: "Turn on automatically"
        subtitle: "Switching it by hand lasts until the next start or end time"

        Switch {
            label: root.what + " schedule"
            checked: root.scheduled
            onToggled: Settings.values[root.prefix + "Scheduled"] = !checked
        }
    }

    Repeater {
        model: [{ title: "From", key: "Start" }, { title: "Until", key: "End" }]

        SettingRow {
            id: timeRow

            required property var modelData

            title: modelData.title
            enabled: root.scheduled

            Stepper {
                label: root.what + " " + timeRow.modelData.title.toLowerCase()
                values: Schedule.quarterHours
                wrap: true
                value: Settings.values[root.prefix + timeRow.modelData.key]
                format: Schedule.format
                onPicked: v => Settings.values[root.prefix + timeRow.modelData.key] = v
            }
        }
    }
}
