import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The to-do widgets, a to-do list of their own (the medium "To-do" and the large "To-do list",
// `large`): the open tasks (services/Planner.qml), as many as fit, click one to tick it off, and
// a field at the bottom to add one.
// The desktop's layer takes no keyboard, so a click in the field asks for it (`wantsKeyboard`,
// which DesktopWidgets.qml follows: taken, then kept until you click elsewhere) until Enter on an
// empty field, Escape or a click in a window.
// On the lock screen (`hidesTitles`) only how many are open.
WidgetSurface {
    id: widget

    medium: true
    property bool hidesTitles: false
    // Typing into the field: the desktop's layer takes the keyboard meanwhile.
    property bool wantsKeyboard: false
    // The layer has the keyboard (its window is active): from then on it only keeps it, and
    // losing it (a click in a window) ends the typing.
    property bool hasKeyboard: false

    readonly property var open: Planner.todos.map((t, i) => ({ text: t.text, done: t.done, index: i })).filter(t => !t.done)
    readonly property int done: Planner.todos.length - open.length
    // As many rows as fit between the heading and the field; when there are more tasks, the
    // last row says how many more.
    readonly property int fit: Math.max(Math.floor(list.height / list.row), 1)
    readonly property bool overflows: open.length > fit
    readonly property var shown: overflows ? open.slice(0, fit - 1) : open

    function startTyping(): void {
        wantsKeyboard = true;
        field.focusInput();
    }

    function stopTyping(): void {
        field.text = "";
        wantsKeyboard = false;
        hasKeyboard = false;
        field.input.focus = false;
    }

    // Asked for and never given (the layer refused): give up rather than wait.
    Timer {
        running: widget.wantsKeyboard && !widget.hasKeyboard
        interval: 1000
        onTriggered: widget.stopTyping()
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

        // Done ones stay in the list (the today menu shows them ticked) until cleared.
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
            visible: widget.overflows || widget.open.length === 0
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
                widget.stopTyping();
                return;
            }
            Planner.add(text.trim());
            text = "";
        }
        onEscaped: widget.stopTyping()

        // The click asks for the keyboard (the field can't have it before the layer does).
        MouseArea {
            anchors.fill: parent
            visible: !widget.wantsKeyboard
            cursorShape: Qt.IBeamCursor
            onClicked: widget.startTyping()
        }

        // The item's focus says nothing about the keyboard (it's set before the layer has it);
        // the window being active does.
        Connections {
            target: field.Window
            function onActiveChanged(): void {
                if (!widget.wantsKeyboard)
                    return;
                if (field.Window.active)
                    widget.hasKeyboard = true;
                else if (widget.hasKeyboard)
                    widget.stopTyping();
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
