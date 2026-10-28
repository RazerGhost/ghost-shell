import QtQuick
import Quickshell
import qs.controlcenter
import qs.services
import qs.theme

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
}
