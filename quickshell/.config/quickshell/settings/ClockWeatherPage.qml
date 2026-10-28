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
    }
}
