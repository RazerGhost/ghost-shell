import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The today menu's note and timer (services/Planner.qml, services/Countdown.qml): a tile for
// each showing what it holds, which opens its part below (one at a time). The to-do list is a
// desktop widget; the note is one too (desktop/NoteWidget.qml).
Column {
    id: root

    // "", "note" or "timer".
    property string open: ""

    spacing: Theme.spacing.s

    function toggle(tool: string): void {
        open = open === tool ? "" : tool;
    }

    // The note and the timer as tiles that show what they hold (the note's first line, the time
    // left); a click unfolds the one below (again folds it).
    Row {
        width: parent.width
        spacing: Theme.spacing.s

        Tile {
            width: (parent.width - parent.spacing) / 2
            icon: "edit_note"
            title: "Note"
            subtitle: Planner.note.trim() === "" ? "Write something down" : Planner.note.trim().split("\n")[0]
            active: root.open === "note"
            Accessible.checkable: true
            Accessible.checked: root.open === "note"
            onClicked: root.toggle("note")
        }

        Tile {
            width: (parent.width - parent.spacing) / 2
            icon: "timer"
            title: "Timer"
            subtitle: Countdown.active ? (Focus.on ? "Focus · " : Focus.onBreak ? "Break · " : "") + Countdown.label + (Countdown.paused ? " · paused" : " left") : "Not running"
            active: Countdown.active || root.open === "timer"
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

    // Timer: a few lengths to start from, and focus mode's (services/Focus.qml); while it runs,
    // the time left with pause and cancel.
    Item {
        visible: root.open === "timer"
        width: parent.width
        implicitHeight: Countdown.active ? Theme.island.height : choices.implicitHeight

        Column {
            id: choices
            visible: !Countdown.active
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacing.xs

            Row {
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

            // Focus mode: the timer with pop-ups held back and the desktop widgets hidden.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacing.xs

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "self_improvement"
                    color: Colors.m3primary
                    font.pixelSize: Theme.icon.small
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Focus"
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }

                Repeater {
                    model: Focus.lengths

                    TextButton {
                        required property int modelData
                        text: modelData + " min"
                        Accessible.name: "Focus for " + modelData + " minutes"
                        onClicked: Focus.start(modelData)
                    }
                }
            }
        }

        Text {
            visible: Countdown.active
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.m
            anchors.verticalCenter: parent.verticalCenter
            text: (Focus.on ? "Focus " : Focus.onBreak ? "Break " : "") + Countdown.label + (Countdown.paused ? " (paused)" : "")
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
