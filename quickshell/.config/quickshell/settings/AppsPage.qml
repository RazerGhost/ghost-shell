import QtQuick
import Quickshell
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets

// Default apps: the terminal, browser and file manager the keybinds open (Super+Enter, Super+B,
// Super+E), and the apps pictures, videos and music files open in. All but the terminal also
// become the system's defaults (links, folders, files).
Column {
    spacing: Theme.spacing.l

    // The installed apps of one kind ("terminal", ...); click one to make it the default.
    component Choice: SettingGroup {
        id: group

        required property string kind

        Repeater {
            model: Apps.candidates(group.kind)

            ListRow {
                required property DesktopEntry modelData
                readonly property bool chosen: modelData.id === Settings.values[group.kind]

                x: Theme.spacing.s
                width: parent.width - Theme.spacing.s * 2
                appIcon: modelData.icon
                title: modelData.name
                subtitle: modelData.genericName
                highlighted: chosen
                trailingIcon: chosen ? "check" : ""
                onActivated: Apps.setDefault(group.kind, modelData.id)

                Accessible.role: Accessible.RadioButton
                Accessible.checkable: true
                Accessible.checked: chosen
            }
        }
    }

    Choice {
        title: "Terminal · Super + Enter"
        kind: "terminal"
    }

    SettingGroup {
        title: "Terminal · greeting"

        SettingRow {
            title: "When a terminal opens"
            subtitle: "Applies to terminals opened from now on"

            Stepper {
                label: "Terminal greeting"
                values: ["ghost", "line", "none"]
                value: Settings.values.terminalGreeting
                format: v => v === "ghost" ? "System summary" : v === "line" ? "One line" : "Nothing"
                onPicked: v => Settings.values.terminalGreeting = v
            }
        }
    }

    Choice {
        title: "Browser · Super + B"
        kind: "browser"
    }

    Choice {
        title: "File manager · Super + E"
        kind: "fileManager"
    }

    Choice {
        title: "Editor · Super + Shift + Z, text files"
        kind: "editor"
    }

    Choice {
        title: "Image viewer · pictures and screenshots"
        kind: "imageViewer"
    }

    Choice {
        title: "Video player"
        kind: "videoPlayer"
    }

    Choice {
        title: "Audio player · music files"
        kind: "audioPlayer"
    }

    // Apps hidden from the launcher (its rows' hide button); Show puts one back.
    SettingGroup {
        title: "Launcher · hidden apps"

        Text {
            visible: (Settings.values.launcherHidden ?? []).length === 0
            leftPadding: Theme.spacing.l
            text: "None. Rest the pointer on an app in the launcher to star or hide it."
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }

        Repeater {
            model: Array.from(Settings.values.launcherHidden ?? [])

            ListRow {
                id: hiddenRow

                required property string modelData
                readonly property DesktopEntry entry: DesktopEntries.byId(modelData)

                x: Theme.spacing.s
                width: parent.width - Theme.spacing.s * 2
                appIcon: entry?.icon ?? ""
                title: entry?.name ?? modelData
                trailingSpace: show.width
                onActivated: show.clicked()

                TextButton {
                    id: show
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Show"
                    onClicked: Settings.values.launcherHidden = Array.from(Settings.values.launcherHidden)
                        .filter(id => id !== hiddenRow.modelData)
                }
            }
        }
    }

    // Your own launcher entries: a name to find it by and a shell command to run.
    SettingGroup {
        id: commands
        title: "Launcher · your commands"

        function add(): void {
            if (name.text.trim() === "" || command.text.trim() === "")
                return;
            Settings.values.launcherCommands = [...Array.from(Settings.values.launcherCommands ?? []),
                                                { name: name.text.trim(), command: command.text.trim() }];
            name.text = "";
            command.text = "";
        }

        Repeater {
            model: Array.from(Settings.values.launcherCommands ?? [])

            ListRow {
                id: commandRow

                required property var modelData
                required property int index

                x: Theme.spacing.s
                width: parent.width - Theme.spacing.s * 2
                icon: "terminal"
                title: modelData.name
                subtitle: modelData.command
                trailingSpace: remove.width

                IconButton {
                    id: remove
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing.s
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "close"
                    label: "Remove " + commandRow.modelData.name
                    onClicked: Settings.values.launcherCommands = Array.from(Settings.values.launcherCommands)
                        .filter((_, i) => i !== commandRow.index)
                }
            }
        }

        Row {
            x: Theme.spacing.s
            width: parent.width - Theme.spacing.s * 2
            spacing: Theme.spacing.s

            TextField {
                id: name
                width: (parent.width - add.width - parent.spacing * 2) * 0.35
                placeholder: "Name"
                onAccepted: command.focusInput()
            }

            TextField {
                id: command
                width: (parent.width - add.width - parent.spacing * 2) * 0.65
                placeholder: "Command, like: ghost theme"
                onAccepted: commands.add()
            }

            TextButton {
                id: add
                anchors.verticalCenter: parent.verticalCenter
                text: "Add"
                enabled: name.text.trim() !== "" && command.text.trim() !== ""
                onClicked: commands.add()
            }
        }
    }
}
