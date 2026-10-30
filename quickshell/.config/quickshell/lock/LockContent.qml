import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
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
    // Your picture above the name (the login screen; greeter/sync.sh copies ~/.face); "" for none.
    property string face
    // Suspend, restart and shut down in the bottom right corner (the login screen).
    property bool powerButtons

    // The clock, for the lock screen editor's outline around it (customize/LockEditor.qml).
    readonly property Item clockItem: bigClock

    signal submitted(string password)
    // A key or a real pointer move: Lock.qml unlocks during the idle lock's grace period.
    signal activity()

    // The lock screens on other monitors clear theirs too after a try; a wrong password also
    // shakes the field.
    function clear(failed: bool): void {
        password.text = "";
        if (failed)
            shake.restart();
    }

    // Takes the keyboard for the password; not inside the lock screen editor, whose own keys
    // (Escape, Enter) would go nowhere then.
    property bool takesKeyboard: true

    Component.onCompleted: {
        if (takesKeyboard)
            password.forceActiveFocus();
    }

    // Fades in from black when it appears (Hyprland shows nothing behind a lock screen).
    opacity: 0
    NumberAnimation on opacity {
        to: 1
        duration: Theme.anim.morph
        easing.type: Theme.anim.easing
    }

    // Where the pointer first showed up: a move away from it counts as activity, so the
    // pointer merely being there when the lock screen appears doesn't.
    property point pointerStart: Qt.point(-1, -1)

    HoverHandler {
        onPointChanged: {
            const p = point.position;
            if (root.pointerStart.x < 0) {
                root.pointerStart = p;
            } else if (Math.abs(p.x - root.pointerStart.x) + Math.abs(p.y - root.pointerStart.y) > Theme.lock.moved) {
                root.activity();
            }
        }
    }

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

    // Moved from there by dragging in the lock screen editor, each on its own: the clock with
    // its date (Settings' lockClockOffset) and the player and widgets under them
    // (lockWidgetsOffset), as fractions of the screen, plus the drag going on (`dragShift`,
    // `widgetsDragShift`, px, until it's let go). Each kept on the screen and off the password
    // field with its hints (LockClock.clamped).
    property point dragShift: Qt.point(0, 0)
    property point widgetsDragShift: Qt.point(0, 0)
    readonly property bool dragging: dragShift.x !== 0 || dragShift.y !== 0 || widgetsDragShift.x !== 0 || widgetsDragShift.y !== 0
    readonly property var fieldArea: ({ x: fieldColumn.x + fieldShift, y: fieldColumn.y, width: fieldColumn.width,
                                        height: fieldColumn.height + belowReserve })
    readonly property var clockOffset: LockClockJs.offset(Settings.values.lockClockOffset)
    readonly property var clockShift: clockShiftFor(clockOffset.x * width + dragShift.x, clockOffset.y * height + dragShift.y)
    readonly property var widgetsOffset: LockClockJs.offset(Settings.values.lockWidgetsOffset)
    readonly property var widgetsShift: widgetsShiftFor(widgetsOffset.x * width + widgetsDragShift.x,
                                                        widgetsOffset.y * height + widgetsDragShift.y)

    // Where each ends up moved (dx, dy) px from its layout's place, clamped.
    function clockShiftFor(dx: real, dy: real): var {
        return LockClockJs.clamped({ x: clockColumn.x, y: clockColumn.y, width: clockColumn.width, height: statusSlot.y },
                                   dx, dy, width, height, fieldArea, Theme.spacing.l * 2, Theme.spacing.l);
    }

    function widgetsShiftFor(dx: real, dy: real): var {
        return LockClockJs.clamped({ x: clockColumn.x + statusSlot.x, y: clockColumn.y + statusSlot.y,
                                     width: statusSlot.width, height: statusSlot.height },
                                   dx, dy, width, height, fieldArea, Theme.spacing.l * 2, Theme.spacing.l);
    }

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
        // Glides to a new place (a look, the arrow keys); follows a drag at once.
        transform: Translate {
            x: root.clockShift.x
            y: root.clockShift.y
            Behavior on x { enabled: !root.dragging; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
            Behavior on y { enabled: !root.dragging; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
        }
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
            // Its own move, less the clock's (which moves the whole column).
            transform: Translate {
                x: root.widgetsShift.x - root.clockShift.x
                y: root.widgetsShift.y - root.clockShift.y
                Behavior on x { enabled: !root.dragging; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
                Behavior on y { enabled: !root.dragging; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
            }
            width: Theme.lock.fieldWidth
            topPadding: Theme.spacing.l * 2
        }
    }

    Column {
        id: fieldColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        // A fifth of the way up; lower when the clock and the lines under it (a large clock,
        // media, weather, battery) reach down that far, so they never overlap.
        // Never lower than leaves room for the hints and messages under it and the message line
        // at the bottom.
        anchors.bottomMargin: root.layout !== "top" ? parent.height * 0.2
            : Math.max(root.belowReserve, Math.min(parent.height * 0.2,
                       parent.height - clockColumn.y - clockColumn.height - Theme.spacing.l * 2 - height))
        // In the bottom-left layout, moved right when a large clock reaches under it.
        transform: Translate { x: root.fieldShift }
        spacing: Theme.spacing.m

        // A wrong password shakes the field side to side, like most lock screens.
        SequentialAnimation {
            id: shake
            readonly property int step: Theme.anim.fast / 3
            NumberAnimation { target: fieldColumn; property: "anchors.horizontalCenterOffset"; to: -Theme.lock.shake; duration: shake.step }
            NumberAnimation { target: fieldColumn; property: "anchors.horizontalCenterOffset"; to: Theme.lock.shake; duration: shake.step * 2 }
            NumberAnimation { target: fieldColumn; property: "anchors.horizontalCenterOffset"; to: -Theme.lock.shake / 2; duration: shake.step * 2 }
            NumberAnimation { target: fieldColumn; property: "anchors.horizontalCenterOffset"; to: 0; duration: shake.step }
        }

        ClippingRectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.user !== "" && faceImage.status === Image.Ready
            width: Theme.lock.face
            height: width
            radius: width / 2
            color: "transparent"

            Image {
                id: faceImage
                anchors.fill: parent
                source: root.face ? "file://" + root.face : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width * 2, height * 2)
                Accessible.ignored: true
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.user !== ""
            spacing: Theme.spacing.s

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: faceImage.status !== Image.Ready
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
                // Not accepted: the key still types.
                Keys.onPressed: event => {
                    root.activity();
                    event.accepted = false;
                }
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
    }

    // The room the field keeps below it: the hints and a message (two lines), and the message
    // line at the bottom when there is one.
    readonly property real belowReserve: Theme.spacing.m * 3 + Theme.font.normal * 4
        + (messageLine.visible ? messageLine.height + Theme.spacing.l * 2 : Theme.spacing.l * 2)

    // How far right the field moves in the bottom-left layout to clear the clock beside it.
    readonly property real fieldShift: layout !== "left" ? 0
        : Math.max(0, clockColumn.x + clockColumn.width + Theme.spacing.l * 2 - (width - fieldColumn.width) / 2)

    // Under the field, hanging from it: the hints and "Wrong password" appear and go without
    // moving the field (in its column they pushed it up into the lines under the clock).
    Column {
        transform: Translate { x: root.fieldShift }
        anchors.top: fieldColumn.bottom
        anchors.topMargin: Theme.spacing.m
        anchors.horizontalCenter: fieldColumn.horizontalCenter
        spacing: Theme.spacing.m

        // Hints while typing: caps lock, and the layout when there's more than one to switch to.
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

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.message !== ""
            text: root.message
            color: root.messageIsError ? Colors.m3error : Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }
    }

    // Your own line at the bottom (Settings -> Lock screen -> Message): "If found, call ...".
    Text {
        id: messageLine
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.l * 2
        width: Math.min(implicitWidth, parent.width * 0.5)
        visible: text !== ""
        text: Settings.values.lockMessage
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.large
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
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
