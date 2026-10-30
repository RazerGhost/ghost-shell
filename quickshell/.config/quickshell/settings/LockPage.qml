import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// The lock screen and the login screen share one look: picture, blur, dimming, clock and date,
// changed on the screen itself in the lock screen editor (customize/LockEditor.qml, the button
// at the top), with the widgets under the clock. This page keeps what isn't seen: the message,
// the grace period, and the login screen's name, picture and power buttons. The
// login screen gets these through greeter/sync.sh, once `ghost greeter` has set it up.
Column {
    id: root

    // Whether the login screen can follow these (`ghost greeter` made its folder yours).
    property bool loginScreenReady: false

    spacing: Theme.spacing.l
    Component.onCompleted: check.running = true

    Process {
        id: check
        command: ["test", "-w", "/var/lib/qs-greeter/shared"]
        onExited: code => root.loginScreenReady = code === 0
    }

    SettingGroup {
        SettingRow {
            title: "Customize the lock screen"
            subtitle: root.loginScreenReady
                      ? "Its clock, picture, look and widgets, on the screen itself. The login screen follows."
                      : "Its clock, picture, look and widgets, on the screen itself. The login screen follows once you run ghost greeter (it needs sudo)."

            TextButton {
                text: "Customize"
                filled: true
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "customize", "lock"])
            }
        }
    }

    SettingGroup {
        title: "Message"

        SettingRow {
            title: "A line at the bottom"
            subtitle: "On both screens, like \"If found, call ...\""

            TextField {
                width: Theme.settings.stepperWide * 1.5
                placeholder: "None"
                Component.onCompleted: text = Settings.values.lockMessage
                input.onTextEdited: Settings.values.lockMessage = text
            }
        }
    }

    SettingGroup {
        title: "Lock screen"

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
        title: "Login screen"

        SettingRow {
            id: faceRow

            readonly property string face: Quickshell.env("HOME") + "/.face"
            property int version: 0 // bumped after a change, so the picture reloads
            property bool exists: false

            title: "Your picture"
            subtitle: "Above your name (~/.face)"

            Row {
                spacing: Theme.spacing.s

                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.icon.launcher
                    height: width
                    radius: width / 2
                    color: Colors.m3surfaceContainerHigh

                    Image {
                        id: faceThumb
                        anchors.fill: parent
                        source: faceRow.exists ? "file://" + faceRow.face + "#" + faceRow.version : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(width * 2, height * 2)
                        cache: false
                        Accessible.ignored: true
                    }
                }

                TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Choose"
                    onClicked: faceDialog.open()
                }

                TextButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: faceRow.exists
                    text: "Remove"
                    onClicked: faceCopy.run(["rm", "-f", faceRow.face])
                }
            }

            FileDialog {
                id: faceDialog
                title: "Your picture"
                nameFilters: ["Pictures (*.png *.jpg *.jpeg *.webp)"]
                onAccepted: faceCopy.run(["cp", decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, "")), faceRow.face])
            }

            Process {
                id: faceCopy
                function run(args: var): void {
                    command = args;
                    running = true;
                }
                onExited: {
                    faceRow.version++;
                    faceCheck.running = true;
                }
            }

            Process {
                id: faceCheck
                command: ["test", "-f", faceRow.face]
                running: true
                onExited: code => faceRow.exists = code === 0
            }
        }

        SettingRow {
            title: "Show your name"
            subtitle: "Above the password field"

            Switch {
                label: "Show your name on the login screen"
                checked: Settings.values.greeterShowName
                onToggled: Settings.values.greeterShowName = !checked
            }
        }

        SettingRow {
            title: "Power buttons"
            subtitle: "Suspend, restart and shut down without logging in"

            Switch {
                label: "Power buttons on the login screen"
                checked: Settings.values.greeterPowerButtons
                onToggled: Settings.values.greeterPowerButtons = !checked
            }
        }
    }
}
