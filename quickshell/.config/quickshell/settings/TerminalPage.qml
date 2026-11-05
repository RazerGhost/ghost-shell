import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "TerminalConfig.js" as TerminalConfig

// The terminal: the prompt's style (Starship; zsh reads it at every prompt, so open terminals
// follow), Ghostty's cursor trail and notifications for long commands (GhosttySettings.qml),
// and what a new terminal shows (ghost-greeting).
Column {
    id: root

    spacing: Theme.spacing.l

    SettingGroup {
        title: "Prompt"

        SettingRow {
            title: "Style"
            subtitle: "Pills: the folder, branch and the rest in colored blocks. Minimal: colored text. Two lines: you, the folder and the rest above where you type."

            Segmented {
                label: "Prompt style"
                options: Object.keys(TerminalConfig.prompts).map(v => ({ value: v, label: v === "pills" ? "Pills" : v === "minimal" ? "Minimal" : "Two lines" }))
                current: Settings.values.terminalPrompt
                onPicked: v => Settings.values.terminalPrompt = v
            }
        }
    }

    SettingGroup {
        title: "Ghostty"

        SettingRow {
            title: "Cursor trail"
            subtitle: "A short streak in the accent color when the cursor jumps"

            Switch {
                label: "Cursor trail"
                checked: Settings.values.terminalCursorTrail
                onToggled: Settings.values.terminalCursorTrail = !checked
            }
        }

        SettingRow {
            title: "Tell me when a long command ends"
            subtitle: "A notification when a command that ran 10 seconds or more finishes while you're in another window"

            Switch {
                label: "Notify when a long command ends"
                checked: Settings.values.terminalNotify
                onToggled: Settings.values.terminalNotify = !checked
            }
        }
    }

    SettingGroup {
        title: "Greeting"

        SettingRow {
            title: "When a terminal opens"
            subtitle: "Applies to terminals opened from now on"

            Segmented {
                label: "Terminal greeting"
                options: [{ value: "ghost", label: "System summary" }, { value: "line", label: "One line" }, { value: "none", label: "Nothing" }]
                current: Settings.values.terminalGreeting
                onPicked: v => Settings.values.terminalGreeting = v
            }
        }
    }
}
