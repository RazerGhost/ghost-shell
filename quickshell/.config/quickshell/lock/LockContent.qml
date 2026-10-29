import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services
import qs.theme
import qs.widgets
import "LockClock.js" as LockClockJs

// What the lock screen shows on each monitor: the wallpaper blurred and darkened, a big clock
// (LockClock.qml) and the date, and the password field. Lock.qml checks the password. The login
// screen (greeter/Greeter.qml) uses it too, with the user's name above the field and power
// buttons. The look (blur, dimming, clock style and place, date) follows Settings -> Lock screen.
// Children go under the date (the lock screen's LockStatus: media and the notification count).
Item {
    id: root

    default property alias status: statusSlot.data

    // Shown under the field: "Wrong password", or PAM's own messages.
    property string message
    property bool messageIsError
    // A password is being checked; the field waits.
    property bool busy
    // The picture behind everything (blurred); "" shows the plain background color.
    property string wallpaper
    // Shown above the password field when set (the login screen).
    property string user
    // Suspend, restart and shut down in the bottom right corner (the login screen).
    property bool powerButtons

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
        source: root.wallpaper ? "file://" + root.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
    }

    MultiEffect {
        anchors.fill: parent
        visible: wallpaper.status === Image.Ready
        source: wallpaper
        blurEnabled: true
        blur: Settings.values.lockBlur / 100
        blurMax: Theme.lock.blur
        brightness: -Settings.values.lockDim / 100 // darker, so the clock and field stand out
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Where the clock sits (Settings -> Lock screen -> Clock): at the top with the field low
    // (the default), both together in the middle, or the clock in the bottom-left corner.
    readonly property string layout: LockClockJs.pick(Settings.values.lockLayout, LockClockJs.layouts)

    states: [
        State {
            when: root.layout === "center"
            AnchorChanges {
                target: clockColumn
                anchors.top: undefined
                anchors.bottom: fieldColumn.top
            }
            PropertyChanges {
                clockColumn.anchors.bottomMargin: Theme.spacing.l * 3
                fieldColumn.anchors.bottomMargin: root.height * 0.32
            }
        },
        State {
            when: root.layout === "left"
            AnchorChanges {
                target: clockColumn
                anchors.top: undefined
                anchors.horizontalCenter: undefined
                anchors.left: root.left
                anchors.bottom: root.bottom
            }
            PropertyChanges {
                clockColumn.anchors.leftMargin: root.width * 0.06
                clockColumn.anchors.bottomMargin: root.height * 0.08
            }
        }
    ]

    Column {
        id: clockColumn

        // Left-aligned in the corner, centered otherwise.
        function place(item: Item): real {
            return root.layout === "left" ? 0 : (width - item.width) / 2;
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.18
        spacing: Theme.spacing.xs

        LockClock {
            id: bigClock
            x: clockColumn.place(this)
            visible: Settings.values.lockClock
            date: clock.date
        }

        Text {
            id: dateLine
            x: clockColumn.place(this)
            visible: Settings.values.lockDate
            topPadding: bigClock.style === "analog" ? Theme.spacing.m : 0
            // English names even with Dutch regional formats, like the calendar.
            text: Qt.locale(Qt.uiLanguage).toString(clock.date, "dddd, d MMMM")
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.title
        }

        Column {
            id: statusSlot
            x: clockColumn.place(this)
            width: Theme.lock.fieldWidth
            topPadding: Theme.spacing.l * 2
        }
    }

    Column {
        id: fieldColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.2
        spacing: Theme.spacing.m

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.user !== ""
            spacing: Theme.spacing.s

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "account_circle"
                color: Colors.m3onSurface
                font.pixelSize: Theme.icon.launcher
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.user
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.large
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.lock.fieldWidth
            height: Theme.slider.height + Theme.spacing.s
            radius: Theme.radius.full
            color: Colors.surfaceTranslucent
            border.width: password.activeFocus ? Theme.outline.normal : 0
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
                // Tab stays here: the buttons below take the keyboard elsewhere (the media
                // card, the login screen's power buttons), and Enter there would suspend or
                // restart, while the password typed after it went nowhere.
                Keys.onTabPressed: event => event.accepted = true
                Keys.onBacktabPressed: event => event.accepted = true

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

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacing.l * 2
        visible: root.powerButtons
        spacing: Theme.spacing.m

        Repeater {
            model: [
                { icon: "bedtime", label: "Suspend", run: "suspend" },
                { icon: "restart_alt", label: "Restart", run: "reboot" },
                { icon: "power_settings_new", label: "Shut down", run: "poweroff" }
            ]

            IconButton {
                required property var modelData
                icon: modelData.icon
                label: modelData.label
                iconSize: Theme.icon.launcher
                color: Colors.m3onSurface
                onClicked: Session[modelData.run]()
            }
        }
    }
}
