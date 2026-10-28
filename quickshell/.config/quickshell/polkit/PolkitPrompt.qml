import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.widgets

// The password prompt apps get when they need permission for something (installing software,
// mounting a disk, changing a system setting): Quickshell is the polkit agent (it replaces
// hyprpolkitagent, which failed to start at login: it came up before Wayland was ready). A
// card over the dimmed screen with what's being asked, whose password, and the field. Enter
// confirms, Escape cancels.
Scope {
    id: root

    readonly property AuthFlow flow: agent.flow

    PolkitAgent {
        id: agent
        // Another agent (hyprpolkitagent) already registered: apps would use that one.
        onIsRegisteredChanged: console.info("Polkit agent registered: " + isRegistered)
    }

    PanelWindow {
        id: window

        visible: agent.isActive
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        // The password goes here and nowhere else.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            if (visible) {
                password.text = "";
                password.forceActiveFocus();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.scrim
        }

        Rectangle {
            anchors.centerIn: parent
            width: Theme.lock.fieldWidth + Theme.spacing.l * 4
            height: content.implicitHeight + Theme.spacing.l * 2
            radius: Theme.radius.xl
            color: Colors.surfaceTranslucent

            Accessible.role: Accessible.Dialog
            Accessible.name: "Authentication required"

            Column {
                id: content

                x: Theme.spacing.l * 2
                y: Theme.spacing.l
                width: parent.width - Theme.spacing.l * 4
                spacing: Theme.spacing.m

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitSize: Theme.icon.launcher * 1.5
                    source: Quickshell.iconPath(root.flow?.iconName || "dialog-password", "dialog-password")
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Authentication required"
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.large
                    font.weight: Font.DemiBold
                }

                // What the app wants to do, in its own words.
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.flow?.message ?? ""
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    wrapMode: Text.Wrap
                }

                // Whose password: usually you; an admin account when that's who can allow it.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacing.s

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "account_circle"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.flow?.selectedIdentity?.displayName ?? ""
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.normal
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    width: parent.width
                    height: Theme.slider.height
                    radius: Theme.radius.full
                    color: Colors.m3surfaceContainerHighest
                    border.width: password.activeFocus ? 2 : 0
                    border.color: root.flow?.supplementaryIsError ? Colors.m3error : Colors.m3primary

                    TextInput {
                        id: password

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Theme.spacing.l
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "●"
                        readOnly: !(root.flow?.isResponseRequired ?? false)
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.large
                        clip: true
                        focus: true

                        Accessible.role: Accessible.EditableText
                        Accessible.name: placeholder.text
                        Accessible.passwordEdit: echoMode === TextInput.Password

                        onAccepted: confirm.submit()
                        Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                        Text {
                            id: placeholder
                            visible: password.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            // polkit's prompt ends with a colon ("Password:").
                            text: (root.flow?.inputPrompt || "Password").replace(/:\s*$/, "")
                            color: Colors.m3onSurfaceVariant
                            font: password.font
                        }
                    }
                }

                // "Sorry, try again", or other news from polkit.
                Text {
                    width: parent.width
                    visible: text !== ""
                    horizontalAlignment: Text.AlignHCenter
                    text: root.flow?.supplementaryMessage ?? ""
                    color: root.flow?.supplementaryIsError ? Colors.m3error : Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    wrapMode: Text.Wrap
                }

                Row {
                    anchors.right: parent.right
                    spacing: Theme.spacing.s

                    TextButton {
                        text: "Cancel"
                        onClicked: root.flow?.cancelAuthenticationRequest()
                    }

                    TextButton {
                        id: confirm

                        function submit(): void {
                            if (!root.flow?.isResponseRequired)
                                return;
                            root.flow.submit(password.text);
                            password.text = "";
                        }

                        text: "Authenticate"
                        filled: true
                        enabled: password.text !== ""
                        onClicked: submit()
                    }
                }
            }
        }
    }
}
