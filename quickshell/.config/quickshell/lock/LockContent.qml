import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// What the lock screen shows on each monitor: the wallpaper blurred and darkened, a big clock
// and the date, and the password field. Lock.qml checks the password.
Item {
    id: root

    // Shown under the field: "Wrong password", or PAM's own messages.
    property string message
    property bool messageIsError
    // A password is being checked; the field waits.
    property bool busy

    signal submitted(string password)

    // The lock screens on other monitors clear theirs too after a try.
    function clear(): void {
        password.text = "";
    }

    Component.onCompleted: password.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: Colors.m3surface
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        visible: false // drawn through the blur below
        source: Wallpaper.path ? "file://" + Wallpaper.path : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
    }

    MultiEffect {
        anchors.fill: parent
        visible: wallpaper.status === Image.Ready
        source: wallpaper
        blurEnabled: true
        blur: 1
        blurMax: Theme.lock.blur
        brightness: -0.25 // darker, so the clock and field stand out
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.18
        spacing: Theme.spacing.xs

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.lock.clock
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            // English names even with Dutch regional formats, like the calendar.
            text: Qt.locale(Qt.uiLanguage).toString(clock.date, "dddd, d MMMM")
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.title
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.2
        spacing: Theme.spacing.m

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.lock.fieldWidth
            height: Theme.slider.height + Theme.spacing.s
            radius: Theme.radius.full
            color: Colors.surfaceTranslucent
            border.width: password.activeFocus ? 2 : 0
            border.color: root.messageIsError ? Colors.m3error : Colors.m3primary

            MaterialIcon {
                id: lockIcon
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.l
                anchors.verticalCenter: parent.verticalCenter
                icon: root.busy ? "hourglass_top" : "lock"
                color: Colors.m3onSurfaceVariant
            }

            TextInput {
                id: password

                anchors.left: lockIcon.right
                anchors.right: parent.right
                anchors.leftMargin: Theme.spacing.m
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
                Accessible.passwordEdit: true

                onAccepted: {
                    if (text !== "")
                        root.submitted(text);
                }
                // Escape clears what was typed, like most lock screens.
                Keys.onEscapePressed: text = ""

                Text {
                    visible: password.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password"
                    color: Colors.m3onSurfaceVariant
                    font: password.font
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.message !== ""
            text: root.message
            color: root.messageIsError ? Colors.m3error : Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }
    }
}
