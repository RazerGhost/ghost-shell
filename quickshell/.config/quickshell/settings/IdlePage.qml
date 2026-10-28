import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.theme
import qs.widgets

// Idle and power: after how long without input the screen dims, locks, turns off and the
// laptop suspends; separately on battery and plugged in (idle/Idle.qml does it).
Column {
    id: root

    spacing: Theme.spacing.l

    readonly property list<int> minutes: [0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 45, 60, 90, 120]

    function format(m: int): string {
        return m === 0 ? "Never" : m < 60 ? m + " min" : m / 60 + " h";
    }

    // The four steps for "Battery" or "Ac" (the setting names' middle part).
    component Steps: SettingGroup {
        id: group

        required property string power

        Repeater {
            model: [
                { step: "Dim", title: "Dim the screen" },
                { step: "Lock", title: "Lock" },
                { step: "ScreenOff", title: "Turn the screen off" },
                { step: "Suspend", title: "Suspend" }
            ]

            SettingRow {
                id: row

                required property var modelData
                readonly property string key: "idle" + group.power + modelData.step

                title: modelData.title

                Stepper {
                    label: row.title + (group.power === "Battery" ? " on battery" : " when plugged in")
                    values: root.minutes
                    value: Settings.values[row.key]
                    format: root.format
                    onPicked: v => Settings.values[row.key] = v
                }
            }
        }
    }

    Text {
        width: parent.width
        leftPadding: Theme.spacing.l
        text: "After how long without input. Apps that keep the screen awake, like a playing video, hold these off. "
              + (UPower.onBattery ? "You're on battery now." : "You're plugged in now.")
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        wrapMode: Text.Wrap
    }

    Steps {
        title: "On battery"
        power: "Battery"
    }

    Steps {
        title: "Plugged in"
        power: "Ac"
    }
}
