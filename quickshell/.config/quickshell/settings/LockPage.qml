import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The lock screen is your desktop, locked (lock/LockContent.qml): its wallpaper and widgets come
// from the desktop editor. This page keeps the rest: a message line and the grace period.
Column {
    id: root

    spacing: Theme.spacing.l

    SettingGroup {
        title: "Message"

        SettingRow {
            title: "A line at the bottom"
            subtitle: "Like \"If found, call ...\""

            TextField {
                width: Theme.settings.stepperWide * 1.5
                placeholder: "None"
                Component.onCompleted: text = Settings.values.lockMessage
                input.onTextEdited: Settings.values.lockMessage = text
            }
        }
    }

    SettingGroup {
        title: "Unlocking"

        SettingRow {
            title: "Grace period"
            subtitle: "After locking by itself, a touch unlocks without the password"

            Stepper {
                label: "Grace period"
                values: [0, 5, 10, 30, 60]
                value: Settings.values.lockGrace
                format: v => v === 0 ? "Off" : v + " s"
                onPicked: v => Settings.values.lockGrace = v
            }
        }
    }
}
