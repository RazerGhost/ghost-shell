import QtQuick
import qs.services
import qs.theme
import qs.widgets

// Weather and clock: the town for the weather in the today menu (services/Weather.qml; the today
// menu asks for it too), and 12- or 24-hour time for the island and the lock screen.
Column {
    id: page

    spacing: Theme.spacing.l

    SettingGroup {
        title: "Weather"

        Item {
            width: parent.width
            height: town.height + Theme.spacing.m * 2

            SearchField {
                id: town
                x: Theme.spacing.m
                y: Theme.spacing.m
                width: parent.width - Theme.spacing.m * 2
                placeholder: Settings.values.weatherLocation
                    ? "Town: " + (Weather.place?.name ?? Settings.values.weatherLocation) + " (type another and press Enter)"
                    : "Your town, for the weather in the today menu"
                onKeyPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        Settings.values.weatherLocation = text.trim();
                        text = "";
                        event.accepted = true;
                    }
                }
            }
        }

        SettingRow {
            visible: Weather.error !== ""
            title: Weather.error
        }

        SettingRow {
            title: "Temperature"

            Stepper {
                label: "Temperature unit"
                values: ["celsius", "fahrenheit"]
                value: Settings.values.temperatureUnit
                format: v => v === "fahrenheit" ? "°F" : "°C"
                onPicked: v => Settings.values.temperatureUnit = v
            }
        }
    }

    SettingGroup {
        title: "Clock"

        SettingRow {
            title: "24-hour clock"
            subtitle: "In the island and on the lock screen. Off: 9:41 PM"

            Switch {
                label: "24-hour clock"
                checked: Settings.values.clock24Hour
                onToggled: Settings.values.clock24Hour = !checked
            }
        }

        SettingRow {
            title: "Show the day"
            subtitle: "In the island: Thu 29  14:32"

            Switch {
                label: "Show the day in the island"
                checked: Settings.values.clockDate
                onToggled: Settings.values.clockDate = !checked
            }
        }

        SettingRow {
            title: "Show seconds"

            Switch {
                label: "Show seconds in the island"
                checked: Settings.values.clockSeconds
                onToggled: Settings.values.clockSeconds = !checked
            }
        }

        SettingRow {
            title: "Music takes the clock's place"
            subtitle: "While music plays the island shows its cover; hover it for the time"

            Switch {
                label: "Music takes the clock's place"
                checked: Settings.values.islandMedia
                onToggled: Settings.values.islandMedia = !checked
            }
        }
    }
}
