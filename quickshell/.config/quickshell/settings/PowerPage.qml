import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.services
import qs.theme
import qs.widgets

// Lock and power: after how long without input the screen dims, locks, turns off and the machine
// suspends, separately on battery and plugged in (idle/Idle.qml does it; without a battery, the
// desktop, only the plugged-in times show), the low battery warning's power saver, the grace
// period after an idle lock, the lock screen's message line, the password and the boot menu. (Until 2026-11-05
// three pages: Power, Lock screen, Account.) The lock screen's look is the desktop's: it's your
// desktop, locked (lock/LockContent.qml).
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
        text: "After how long without input. Apps that keep the screen awake, like a playing video, hold these off."
              + (Battery.present ? (UPower.onBattery ? " You're on battery now." : " You're plugged in now.") : "")
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        wrapMode: Text.Wrap
    }

    Steps {
        title: "On battery"
        power: "Battery"
        visible: Battery.present
    }

    Steps {
        title: Battery.present ? "Plugged in" : "When idle"
        power: "Ac"
    }

    SettingGroup {
        title: "Low battery"
        visible: Battery.present

        SettingRow {
            title: "Power saver when the battery is low"
            subtitle: "From the 20 % warning until you plug in; then back to the mode you had"

            Switch {
                label: "Power saver when the battery is low"
                checked: Settings.values.batterySaver
                onToggled: Settings.values.batterySaver = !checked
            }
        }
    }

    // How Limine's boot menu shows, to start Windows, another kernel or a snapshot: only where the
    // system module installed its helper (machines that boot with Limine). Root's file, so it's
    // changed through pkexec (your password in the shell's own prompt; the polkit action allows
    // only ghost-boot-menu), and the choice is saved once that worked.
    SettingGroup {
        id: boot

        property bool available: false
        property string pending: ""
        property string note: ""

        visible: available
        title: "Starting up"

        Process {
            running: true
            command: ["test", "-x", "/usr/local/lib/ghost-boot-menu"]
            onExited: code => boot.available = code === 0
        }

        SettingRow {
            title: "Boot menu"
            subtitle: boot.note !== "" ? boot.note
                : "To start Windows, another kernel or a snapshot. Hidden: press a key as the machine starts"

            Segmented {
                label: "Boot menu"
                enabled: !apply.running
                options: [{ value: "hidden", label: "Hidden" }, { value: "shown", label: "Shown 3 s" },
                          { value: "remember", label: "Remember last" }]
                current: boot.pending !== "" ? boot.pending : Settings.values.bootMenu
                onPicked: v => {
                    if (v === Settings.values.bootMenu)
                        return;
                    boot.pending = v;
                    boot.note = "";
                    apply.command = ["pkexec", "/usr/local/lib/ghost-boot-menu", v];
                    apply.running = true;
                }
            }
        }

        Process {
            id: apply
            onExited: code => {
                if (code === 0)
                    Settings.values.bootMenu = boot.pending;
                else
                    boot.note = "Not changed: the password was cancelled or the boot menu couldn't be written";
                boot.pending = "";
            }
        }
    }

    SettingGroup {
        title: "Unlocking"

        SettingRow {
            title: "Grace period"
            subtitle: "After locking by itself, a touch unlocks without the password"

            Stepper {
                label: "Grace period"
                values: [0, 5, 10, 30, 60]
                value: Settings.values.lockGrace
                format: v => v === 0 ? "Off" : v + " s"
                onPicked: v => Settings.values.lockGrace = v
            }
        }
    }

    SettingGroup {
        title: "Lock screen"

        SettingRow {
            title: "A line at the bottom"
            subtitle: "Like \"If found, call ...\""

            TextField {
                width: Theme.settings.stepperWide * 1.5
                placeholder: "None"
                Component.onCompleted: text = Settings.values.lockMessage
                input.onTextEdited: Settings.values.lockMessage = text
            }
        }
    }

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
