import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The to-do widgets, a to-do list of their own (the medium "To-do" and the large "To-do list",
// `large`): the open tasks (services/Planner.qml), as many as fit, click one to tick it off, and
// a field at the bottom to add one.
// A click in the field takes the keyboard (WidgetKeyboard.qml) until Enter on an empty field,
// Escape or a click in a window.
// On the lock screen (`hidesTitles`) only how many are open.
WidgetSurface {
    id: widget

    medium: true
    property bool hidesTitles: false
    // Typing into the field: the desktop's layer has the keyboard meanwhile (WidgetStage.qml).
    readonly property alias keyboard: keyboard

    readonly property var open: Planner.todos.map((t, i) => ({ text: t.text, done: t.done, index: i })).filter(t => !t.done)
    readonly property int done: Planner.todos.length - open.length
    // As many rows as fit between the heading and the field; when there are more tasks, the
    // last row says how many more. With room for one row only (the medium size at small text
    // sizes), the first task, without the line.
    readonly property int fit: Math.max(Math.floor(list.height / list.row), 1)
    readonly property bool overflows: open.length > fit
    readonly property bool showsMore: overflows && fit > 1
    readonly property var shown: overflows ? open.slice(0, showsMore ? fit - 1 : 1) : open

    WidgetKeyboard {
        id: keyboard
        onStopped: {
            field.text = "";
            field.input.focus = false;
        }
    }

    Item {
        id: heading
        width: parent.width
        height: title.height

        Text {
            id: title
            text: "TO-DO"
            color: Colors.m3primary
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        // Ticked-off tasks are kept (in today.json) until cleared here.
        Text {
            anchors.right: parent.right
            visible: !widget.hidesTitles && widget.done > 0
            text: "Clear " + widget.done + " done"
            color: clear.containsMouse ? Colors.m3primary : Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold

            MouseArea {
                id: clear
                anchors.fill: parent
                anchors.margins: -Theme.spacing.xs
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Planner.clearDone()

                Accessible.role: Accessible.Button
                Accessible.name: parent.text
                Accessible.onPressAction: Planner.clearDone()
            }
        }
    }

    Column {
        id: list

        readonly property int row: Theme.font.normal * 2

        anchors.top: heading.bottom
        anchors.topMargin: Theme.spacing.s
        anchors.bottom: field.top
        anchors.bottomMargin: Theme.spacing.s
        width: parent.width
        visible: !widget.hidesTitles

        Repeater {
            model: widget.shown

            MouseArea {
                id: task

                required property var modelData

                width: parent.width
                height: list.row
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Planner.toggle(modelData.index)

                Accessible.role: Accessible.CheckBox
                Accessible.name: modelData.text
                Accessible.checkable: true
                Accessible.checked: false
                Accessible.onPressAction: Planner.toggle(modelData.index)

                MaterialIcon {
                    id: check
                    anchors.verticalCenter: parent.verticalCenter
                    // Filled for a moment under the pointer: what a click will do.
                    icon: task.containsMouse ? "check_circle" : "radio_button_unchecked"
                    color: task.containsMouse ? Colors.m3primary : Colors.m3onSurfaceVariant
                    font.pixelSize: Theme.icon.small
                }

                Text {
                    anchors.left: check.right
                    anchors.leftMargin: Theme.spacing.s
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: task.modelData.text
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            id: more
            visible: widget.showsMore || widget.open.length === 0
            text: widget.open.length === 0 ? (widget.done > 0 ? "All done" : "Nothing to do")
                : "+" + (widget.open.length - widget.shown.length) + " more"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: widget.open.length === 0 ? Theme.font.large : Theme.font.small
        }
    }

    TextField {
        id: field
        anchors.bottom: parent.bottom
        width: parent.width
        visible: !widget.hidesTitles
        placeholder: "Add a task"
        keepsEscape: true
        onAccepted: {
            if (text.trim() === "") {
                keyboard.stop();
                return;
            }
            Planner.add(text.trim());
            text = "";
        }
        onEscaped: keyboard.stop()

        // The click asks for the keyboard (the field can't have it before the layer does). Not in
        // the desktop editor: its widgets are being placed there, and the editor has the keyboard.
        enabled: !Editing.desktop

        MouseArea {
            anchors.fill: parent
            visible: !keyboard.wantsKeyboard
            cursorShape: Qt.IBeamCursor
            onClicked: {
                keyboard.start();
                field.focusInput();
            }
        }
    }

    // On the lock screen: only how many, large, like the to-do and notifications widgets.
    Column {
        visible: widget.hidesTitles
        anchors.bottom: parent.bottom
        width: parent.width

        Text {
            text: widget.open.length
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.desktop.clock
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        Text {
            width: parent.width
            text: widget.open.length === 0 ? (widget.done > 0 ? "All done" : "Nothing to do")
                : widget.open.length === 1 ? "Task open" : "Tasks open"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            elide: Text.ElideRight
        }
    }
}
