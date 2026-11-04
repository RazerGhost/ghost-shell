import QtQuick
import qs.bar
import qs.services
import qs.theme
import qs.widgets

// The lock screen's island (LockContent.qml; user's choice, 2026-11-04: the lock screen should
// feel like the desktop, not a separate screen): the desktop's island in its place at the top,
// with a lock and the time, opening into the password field the way it opens into its menus.
// Open while something is typed, checked or said, and for a while after a key or a pointer
// move; closed again after a quiet spell. The field keeps the keyboard while closed (clipped,
// not hidden), so the first key typed both opens it and counts.
Item {
    id: root

    property string message
    property bool messageIsError
    property bool busy
    // The password was right: closed, with the lock open, the moment before the desktop shows.
    property bool unlocking

    signal submitted(string password)
    // A key in the field: the lock screen's activity (the idle lock's grace period).
    signal typed()

    readonly property alias field: password
    // Its shape and how far it's shaken, for the lock screen's glass behind it (LockContent.qml).
    readonly property alias pill: pill
    readonly property real shake: shakeOffset.x

    // Opens it for a while (a key, a pointer move, the lock screen appearing).
    function wake(): void {
        awake = true;
        sleep.restart();
    }

    function clear(failed: bool): void {
        password.text = "";
        if (failed)
            shake.restart();
    }

    property bool awake: false
    readonly property bool open: !unlocking && (awake || password.text !== "" || busy || message !== "")

    Timer {
        id: sleep
        interval: Theme.lock.islandAwake
        onTriggered: root.awake = false
    }

    // Pops open a moment after the lock screen appears, so it's seen opening.
    Timer {
        running: true
        interval: Theme.anim.normal
        onTriggered: root.wake()
    }

    IslandPill {
        id: pill

        shown: root.open ? "password" : ""
        transform: Translate { id: shakeOffset }

        // A wrong password shakes it side to side, like most lock screens.
        SequentialAnimation {
            id: shake
            readonly property int step: Theme.anim.fast / 3
            NumberAnimation { target: shakeOffset; property: "x"; to: -Theme.lock.shake; duration: shake.step }
            NumberAnimation { target: shakeOffset; property: "x"; to: Theme.lock.shake; duration: shake.step * 2 }
            NumberAnimation { target: shakeOffset; property: "x"; to: -Theme.lock.shake / 2; duration: shake.step * 2 }
            NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: shake.step }
        }

        row: Row {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: Theme.island.padding + Theme.spacing.m
            rightPadding: leftPadding
            spacing: Theme.spacing.s

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: root.unlocking ? "lock_open" : root.busy ? "hourglass_top" : "lock"
                color: root.unlocking ? Colors.m3primary : Colors.m3onSurfaceVariant
                font.pixelSize: Theme.icon.small
            }

            Clock {}
        }

        // The password field, with the hints and messages under it.
        Item {
            readonly property bool shown: root.open
            width: parent.width
            implicitHeight: body.implicitHeight

            Column {
                id: body

                x: Theme.spacing.s
                width: parent.width - Theme.spacing.s * 2
                topPadding: Theme.spacing.xs
                bottomPadding: Theme.spacing.s
                spacing: Theme.spacing.s

                Rectangle {
                    width: parent.width
                    height: Theme.slider.height + Theme.spacing.s
                    radius: Theme.radius.full
                    color: Colors.tint
                    border.width: password.activeFocus ? Theme.outline.normal : 0
                    border.color: root.messageIsError ? Colors.m3error : Colors.m3primary

                    TextInput {
                        id: password

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Theme.spacing.l
                        anchors.rightMargin: Theme.spacing.l
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        readOnly: root.busy
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.large
                        clip: true
                        focus: true

                        Accessible.role: Accessible.EditableText
                        Accessible.name: "Password"
                        Accessible.description: "Screen locked"
                        Accessible.passwordEdit: true

                        onAccepted: {
                            if (text !== "")
                                root.submitted(text);
                        }
                        // Escape clears what was typed, like most lock screens.
                        Keys.onEscapePressed: text = ""
                        // Not accepted: the key still types.
                        Keys.onPressed: event => {
                            root.wake();
                            root.typed();
                            event.accepted = false;
                        }
                        // Tab stays here: the buttons elsewhere (the media card) would take the
                        // keyboard, and the password typed after it went nowhere.
                        Keys.onTabPressed: event => event.accepted = true
                        Keys.onBacktabPressed: event => event.accepted = true

                        Text {
                            visible: password.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            Accessible.ignored: true // the field's own name already says it
                            text: "Password"
                            color: Colors.m3onSurfaceVariant
                            font: password.font
                        }
                    }
                }

                // Hints while typing: caps lock, and the layout when there's more than one.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: Keyboard.capsLock || Keyboard.layoutCount > 1
                    spacing: Theme.spacing.l

                    Repeater {
                        model: [
                            { shown: Keyboard.capsLock, icon: "keyboard_capslock", text: "Caps lock is on" },
                            { shown: Keyboard.layoutCount > 1, icon: "keyboard", text: Keyboard.layout }
                        ]

                        Row {
                            required property var modelData
                            visible: modelData.shown
                            spacing: Theme.spacing.xs

                            // Said aloud when it appears.
                            Accessible.role: Accessible.AlertMessage
                            Accessible.name: modelData.text

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: parent.modelData.icon
                                color: Colors.m3onSurfaceVariant
                                font.pixelSize: Theme.icon.small
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.modelData.text
                                color: Colors.m3onSurfaceVariant
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.normal
                            }
                        }
                    }
                }

                // "Wrong password", or PAM's own messages; said aloud when it appears.
                Text {
                    width: parent.width
                    visible: root.message !== ""
                    Accessible.role: Accessible.AlertMessage
                    Accessible.name: root.message
                    text: root.message
                    color: root.messageIsError ? Colors.m3error : Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
