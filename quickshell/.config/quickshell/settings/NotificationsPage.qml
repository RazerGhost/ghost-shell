import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "../services/NotificationRules.js" as Rules

// Notifications: Do Not Disturb, how long pop-ups (and the volume and brightness one) stay and
// where, an optional daily schedule (e.g. at night), and each app that has sent one: silent,
// pop up, or always pop up.
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

        SettingRow {
            title: "Also while a window is fullscreen"
            subtitle: "Games and films aren't interrupted; afterwards you're told how many came in"

            Switch {
                label: "Do Not Disturb while a window is fullscreen"
                checked: Settings.values.dndFullscreen
                onToggled: Settings.values.dndFullscreen = !checked
            }
        }
    }

    SettingGroup {
        title: "Pop-ups"

        SettingRow {
            title: "Notifications stay for"
            subtitle: "Hovering one keeps it; critical ones stay until you close them"

            Stepper {
                label: "Notifications stay for"
                values: [3, 5, 8, 12, 20, 30]
                value: Settings.values.notificationSeconds
                format: v => v + " s"
                onPicked: v => Settings.values.notificationSeconds = v
            }
        }

        SettingRow {
            title: Brightness.level >= 0 ? "Volume and brightness pop-up" : "Volume pop-up"
            subtitle: "Also caps lock, keyboard layout and power mode"

            Segmented {
                label: "Volume and brightness pop-up position"
                options: [{ value: "bottom", label: "Bottom" }, { value: "top", label: "Top" }]
                current: Settings.values.osdPosition
                onPicked: v => Settings.values.osdPosition = v
            }
        }

        SettingRow {
            title: "It stays for"

            Stepper {
                label: "Volume and brightness pop-up time"
                values: [1, 1.5, 2, 3, 5]
                value: Settings.values.osdSeconds
                format: v => v + " s"
                onPicked: v => Settings.values.osdSeconds = v
            }
        }
    }

    // Which pop-ups the OSD shows (osd/Osd.qml), each on or off.
    SettingGroup {
        title: "Pop-ups for"

        Repeater {
            model: [
                { key: "volume", title: "Volume" },
                { key: "brightness", title: "Brightness", needs: "brightness" },
                { key: "mic", title: "Microphone on or off" },
                { key: "mutedMic", title: "An app recording while the microphone is muted" },
                { key: "output", title: "A new sound output (headphones)" },
                { key: "vpn", title: "A VPN connecting or disconnecting" },
                { key: "power", title: "Power mode" },
                { key: "layout", title: "Keyboard layout" },
                { key: "capsLock", title: "Caps lock" }
            ].filter(kind => kind.needs !== "brightness" || Brightness.level >= 0) // no backlight, no brightness (the desktop)

            SettingRow {
                id: kindRow

                required property var modelData
                readonly property var hidden: Array.from(Settings.values.hiddenOsdKinds ?? [])

                title: modelData.title

                Switch {
                    label: "Pop-up for " + kindRow.modelData.title
                    checked: !kindRow.hidden.includes(kindRow.modelData.key)
                    onToggled: Settings.values.hiddenOsdKinds = checked
                        ? [...kindRow.hidden, kindRow.modelData.key]
                        : kindRow.hidden.filter(k => k !== kindRow.modelData.key)
                }
            }
        }
    }

    ScheduleGroup {
        prefix: "dnd"
        what: "Do Not Disturb"
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

                Segmented {
                    label: "Notifications from " + appRow.modelData
                    options: Rules.modes.map(v => ({ value: v, label: Rules.labels[v] }))
                    current: Rules.mode(Settings.values.notificationApps, appRow.modelData)
                    onPicked: v => Settings.values.notificationApps = Rules.withMode(Settings.values.notificationApps, appRow.modelData, v)
                }
            }
        }
    }
}
