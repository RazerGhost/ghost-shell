import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The today menu's to-do list, note and timer (services/Planner.qml, services/Countdown.qml):
// a button for each, which opens its part below (one at a time, folded like the calendar).
Column {
    id: root

    // "", "todo", "note" or "timer".
    property string open: ""

    spacing: Theme.spacing.s

    function toggle(tool: string): void {
        open = open === tool ? "" : tool;
    }

    Row {
        spacing: Theme.spacing.xs

        TextButton {
            text: Planner.open > 0 ? "To-do · " + Planner.open : "To-do"
            filled: root.open === "todo"
            Accessible.checkable: true
            Accessible.checked: root.open === "todo"
            onClicked: root.toggle("todo")
        }

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

    // A rounded text field, like the Wi-Fi password's.
    component Field: Rectangle {
        property alias input: field

        implicitHeight: Theme.slider.height
        radius: Theme.radius.full
        color: Colors.m3surfaceContainerHighest

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.l
            anchors.rightMargin: Theme.spacing.l
            verticalAlignment: TextInput.AlignVCenter
            color: Colors.m3onSurface
            selectionColor: Colors.m3primary
            selectedTextColor: Colors.m3onPrimary
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            clip: true
        }
    }

    // To-do: type and Enter to add; click a task to tick it off.
    Column {
        visible: root.open === "todo"
        width: parent.width
        spacing: Theme.spacing.xs

        onVisibleChanged: {
            if (visible)
                newTask.input.forceActiveFocus();
        }

        Field {
            id: newTask
            width: parent.width
            input.Accessible.role: Accessible.EditableText
            input.Accessible.name: "New task"
            input.onAccepted: {
                Planner.add(input.text);
                input.text = "";
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.l
                anchors.verticalCenter: parent.verticalCenter
                visible: newTask.input.text === ""
                text: "Add a task"
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
            }
        }

        Repeater {
            model: Planner.todos

            MouseArea {
                id: task

                required property var modelData
                required property int index

                width: parent.width
                implicitHeight: Theme.list.rowHeight * 0.75
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Planner.toggle(index)

                Accessible.role: Accessible.CheckBox
                Accessible.name: modelData.text
                Accessible.checkable: true
                Accessible.checked: modelData.done
                Accessible.onPressAction: Planner.toggle(index)

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius.m
                    color: Colors.m3onSurface
                    opacity: task.containsMouse ? Theme.state.hover : 0
                }

                MaterialIcon {
                    id: check
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.m
                    anchors.verticalCenter: parent.verticalCenter
                    icon: task.modelData.done ? "check_circle" : "radio_button_unchecked"
                    color: task.modelData.done ? Colors.m3primary : Colors.m3onSurfaceVariant
                }

                Text {
                    anchors.left: check.right
                    anchors.leftMargin: Theme.spacing.m
                    anchors.right: removeTask.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: task.modelData.text
                    elide: Text.ElideRight
                    font.strikeout: task.modelData.done
                    color: task.modelData.done ? Colors.m3onSurfaceVariant : Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                }

                IconButton {
                    id: removeTask
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    // Always there (screen readers only see what's visible), faint until hovered.
                    opacity: task.containsMouse ? 1 : Theme.state.disabled
                    icon: "close"
                    label: "Remove " + task.modelData.text
                    iconSize: Theme.icon.small
                    onClicked: Planner.remove(task.index)
                }
            }
        }

        TextButton {
            anchors.right: parent.right
            visible: Planner.todos.some(t => t.done)
            text: "Clear done"
            onClicked: Planner.clearDone()
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
                model: [1, 5, 15, 25]

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
