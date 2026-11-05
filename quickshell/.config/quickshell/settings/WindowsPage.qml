import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// Windows: the hot corner, and whether floating apps reopen where they were. Their look, gaps
// and motion are the windows editor's (Appearance -> Customize).
Column {
    id: page

    spacing: Theme.spacing.l

    SettingGroup {
        title: "Behaviour"

        SettingRow {
            title: "Hot corner"
            subtitle: "Resting the pointer in the top-left corner opens the overview"

            Switch {
                label: "Hot corner"
                checked: Settings.values.hotCorner
                onToggled: Settings.values.hotCorner = !checked
            }
        }

        SettingRow {
            title: "Reopen floating apps where they were"
            subtitle: "A floating window comes back at the position and size it had when it closed"

            Switch {
                label: "Reopen floating apps where they were"
                checked: Settings.values.rememberPositions
                onToggled: Settings.values.rememberPositions = !checked
            }
        }
    }
}
