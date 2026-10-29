import QtQuick
import qs.theme

// A rounded text field with a placeholder, like SearchField without the magnifier: the Wi-Fi
// password, the today menu's new task, a notification's quick reply. `password` hides what's
// typed; Enter sends `accepted`. `input` is the TextInput, for focus and anything else.
Rectangle {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder
    property bool password: false

    signal accepted()

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitHeight: Theme.slider.height
    radius: Theme.radius.full
    color: Colors.m3surfaceContainerHighest
    // Where the typing goes, like the lock screen's and the password prompt's fields.
    border.width: input.activeFocus ? Theme.outline.normal : 0
    border.color: Colors.m3primary

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.l
        anchors.rightMargin: Theme.spacing.l
        verticalAlignment: TextInput.AlignVCenter
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        color: Colors.m3onSurface
        selectionColor: Colors.m3primary
        selectedTextColor: Colors.m3onPrimary
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.normal
        clip: true
        activeFocusOnTab: true

        Accessible.role: Accessible.EditableText
        Accessible.name: root.placeholder
        Accessible.passwordEdit: root.password

        onAccepted: root.accepted()

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: Colors.m3onSurfaceVariant
            font: input.font
        }
    }
}
