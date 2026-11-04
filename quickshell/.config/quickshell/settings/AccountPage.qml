import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// Your account: the password you log in, unlock and use sudo with (one password: sudo asks for
// your own). Changed with `passwd` in your terminal, so the shell never sees or handles it.
Column {
    id: root

    spacing: Theme.spacing.l

    SettingGroup {
        title: "Password"

        SettingRow {
            title: "Change your password"
            subtitle: "For the lock screen and sudo (signed in as " + Quickshell.env("USER") + "). Opens a terminal that asks for the old one, then the new one twice."

            TextButton {
                text: "Change"
                filled: true
                // The terminal stays open after passwd until Enter, so its answer can be read.
                onClicked: Apps.runInTerminal(["sh", "-c", "passwd; echo; printf 'Press Enter to close. '; read -r _"])
            }
        }
    }
}
