import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The to-do widgets, a to-do list of their own (the medium "To-do" and the large "To-do list",
// `large`): the open tasks (services/Planner.qml), a list that scrolls with the wheel or
// touchpad, click one to tick it off, and a field at the bottom to add one.
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

    // Keyboard mode: the task the keys are on, -1 for none (Enter then types a new one).
    property int pick: -1
    onChosenChanged: pick = -1

    function startTyping(): void {
        keyboard.start();
        field.focusInput();
    }

    // Up and Down through the tasks (on past the ends to the next widget), Enter ticks the one
    // picked off, or with none picked types a new one.
    function key(event: var): bool {
        if (hidesTitles)
            return false;
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            const next = pick + (event.key === Qt.Key_Down ? 1 : -1);
            if (next < -1 || next >= open.length)
                return false;
            pick = next;
            if (pick >= 0)
                list.positionViewAtIndex(pick, ListView.Contain);
            return true;
        }
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space)
            return false;
        if (pick < 0) {
            startTyping();
        } else {
            const task = open[pick];
            const left = open.length - 1;
            list.keepingPlace(() => Planner.toggle(task.index));
            pick = Math.min(pick, left - 1);
        }
        return true;
    }

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

    ListView {
        id: list

        readonly property int row: Theme.font.normal * 2

        anchors.top: heading.bottom
        anchors.topMargin: Theme.spacing.s
        anchors.bottom: field.top
        anchors.bottomMargin: Theme.spacing.s
        width: parent.width - Theme.desktop.scrollMark - Theme.spacing.xs
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: !widget.hidesTitles
        model: widget.open

        // The list is built again when a task is ticked off; stay where it was scrolled to.
        function keepingPlace(change: var): void {
            const y = contentY;
            change();
            Qt.callLater(() => contentY = Math.max(0, Math.min(y, contentHeight - height)));
        }

        delegate: MouseArea {
            id: task

            required property var modelData
            required property int index
            // Under the pointer, or picked in keyboard mode: what a click or Enter will do.
            readonly property bool lit: containsMouse || (widget.chosen && widget.pick === index)

            width: ListView.view.width
            height: list.row
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: list.keepingPlace(() => Planner.toggle(modelData.index))

            Accessible.role: Accessible.CheckBox
            Accessible.name: modelData.text
            Accessible.checkable: true
            Accessible.checked: false
            Accessible.onPressAction: Planner.toggle(modelData.index)

            MaterialIcon {
                id: check
                anchors.verticalCenter: parent.verticalCenter
                icon: task.lit ? "check_circle" : "radio_button_unchecked"
                color: task.lit ? Colors.m3primary : Colors.m3onSurfaceVariant
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

        Text {
            visible: widget.open.length === 0
            text: widget.done > 0 ? "All done" : "Nothing to do"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
        }
    }

    ScrollMark {
        flickable: list
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
            onClicked: widget.startTyping()
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
