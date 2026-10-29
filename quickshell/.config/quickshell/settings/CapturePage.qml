import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "../services/CaptureFolders.js" as CaptureFolders

// Screenshots and recordings (the capture module): where they're saved, and how recordings are
// made (frame rate, quality, the microphone). Folders: type one and press Enter; empty is the
// default; "~/..." is in your home folder.
Column {
    id: page

    readonly property string home: Quickshell.env("HOME")

    spacing: Theme.spacing.l

    SettingGroup {
        title: "Screenshots"

        Item {
            width: parent.width
            height: shots.height + Theme.spacing.m * 2

            FolderField {
                id: shots
                x: Theme.spacing.m
                y: Theme.spacing.m
                width: parent.width - Theme.spacing.m * 2
                key: "screenshotFolder"
                fallback: page.home + "/Pictures/Screenshots"
                home: page.home
            }
        }
    }

    SettingGroup {
        title: "Recordings"

        Item {
            width: parent.width
            height: clips.height + Theme.spacing.m * 2

            FolderField {
                id: clips
                x: Theme.spacing.m
                y: Theme.spacing.m
                width: parent.width - Theme.spacing.m * 2
                key: "recordingFolder"
                fallback: page.home + "/Videos/Recordings"
                home: page.home
            }
        }

        SettingRow {
            title: "Frame rate"

            Stepper {
                label: "Recording frame rate"
                values: [30, 60]
                value: Settings.values.recordingFps
                format: v => v + " fps"
                onPicked: v => Settings.values.recordingFps = v
            }
        }

        SettingRow {
            title: "Quality"
            subtitle: "Higher makes bigger files"

            Stepper {
                label: "Recording quality"
                values: ["medium", "high", "very_high", "ultra"]
                value: Settings.values.recordingQuality
                format: v => ({ medium: "Medium", high: "High", very_high: "Very high", ultra: "Ultra" })[v]
                onPicked: v => Settings.values.recordingQuality = v
            }
        }

        SettingRow {
            title: "Record the microphone too"
            subtitle: "Mixed with the desktop's sound"

            Switch {
                label: "Record the microphone too"
                checked: Settings.values.recordingMic
                onToggled: Settings.values.recordingMic = !checked
            }
        }
    }
}
