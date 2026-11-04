import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The today menu's note and timer (services/Planner.qml, services/Countdown.qml): a button for
// each, which opens its part below (one at a time). The to-do list is a desktop widget.
Column {
    id: root

    // "", "note" or "timer".
    property string open: ""

    spacing: Theme.spacing.s

    function toggle(tool: string): void {
        open = open === tool ? "" : tool;
    }

    Row {
        spacing: Theme.spacing.xs

        TextButton {
            text: "Note"
            filled: root.open === "note"
            Accessible.checkable: true
            Accessible.checked: root.open === "note"
            onClicked: root.toggle("note")
        }

        TextButton {
            text: Countdown.active ? "Timer · " + Countdown.label : "Timer"
            filled: root.open === "timer"
            Accessible.checkable: true
            Accessible.checked: root.open === "timer"
            onClicked: root.toggle("timer")
        }
    }

    // One note, saved while typing.
    Rectangle {
        visible: root.open === "note"
        width: parent.width
        implicitHeight: Math.max(Theme.slider.height * 3, note.implicitHeight + Theme.spacing.m * 2)
        radius: Theme.radius.m
        color: Colors.m3surfaceContainerHighest

        onVisibleChanged: {
            if (visible) {
                note.text = Planner.note;
                note.forceActiveFocus();
            }
        }

        TextEdit {
            id: note
            anchors.fill: parent
            anchors.margins: Theme.spacing.m
            wrapMode: TextEdit.Wrap
            color: Colors.m3onSurface
            selectionColor: Colors.m3primary
            selectedTextColor: Colors.m3onPrimary
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            Accessible.role: Accessible.EditableText
            Accessible.name: "Note"
            onTextChanged: {
                if (root.open === "note")
                    Planner.setNote(text);
            }
        }

        Text {
            anchors.fill: note
            visible: note.text === ""
            text: "Write something down"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }
    }

    // Timer: a few lengths to start from; while it runs, the time left with pause and cancel.
    Item {
        visible: root.open === "timer"
        width: parent.width
        implicitHeight: Theme.island.height

        Row {
            visible: !Countdown.active
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacing.xs

            Repeater {
                model: Countdown.lengths

                TextButton {
                    required property int modelData
                    text: modelData + " min"
                    onClicked: Countdown.start(modelData)
                }
            }
        }

        Text {
            visible: Countdown.active
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.m
            anchors.verticalCenter: parent.verticalCenter
            text: Countdown.label + (Countdown.paused ? " (paused)" : "")
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.title
            font.features: { "tnum": 1 } // digits of equal width, so the time doesn't jitter
        }

        Row {
            visible: Countdown.active
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacing.xs

            TextButton {
                text: Countdown.paused ? "Resume" : "Pause"
                onClicked: Countdown.paused ? Countdown.resume() : Countdown.pause()
            }

            TextButton {
                text: "Cancel"
                onClicked: Countdown.cancel()
            }
        }
    }
}
