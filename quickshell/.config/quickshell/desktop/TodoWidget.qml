import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.widgets

// The to-do widget (medium), like iOS's Reminders: the today menu's tasks that aren't done yet
// (services/Planner.qml), click one to tick it off. Tasks are added in the today menu, which
// clicking the heading opens. On the lock screen (`hidesTitles`) only how many are open.
WidgetSurface {
    id: widget

    medium: true
    property bool hidesTitles: false

    // The open tasks with their place in the whole list (what Planner.toggle takes).
    readonly property var open: Planner.todos.map((t, i) => ({ text: t.text, done: t.done, index: i })).filter(t => !t.done)
    readonly property int rows: 3

    MouseArea {
        id: heading
        width: parent.width
        height: title.height
        cursorShape: Qt.PointingHandCursor
        onClicked: openToday()

        function openToday(): void {
            Quickshell.execDetached(["qs", "ipc", "call", "island", "toggle", "today"]);
        }

        // A button on the desktop; on the lock screen (disabled) plain text with no action.
        Accessible.role: enabled ? Accessible.Button : Accessible.StaticText
        Accessible.name: "To-do, " + widget.open.length + " open" + (enabled ? ": open the today menu" : "")
        Accessible.onPressAction: openToday()

        Text {
            id: title
            text: "TO-DO"
            color: Colors.m3primary
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Text {
            anchors.right: parent.right
            visible: !widget.hidesTitles // the large count below says it
            text: widget.open.length
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
        }
    }

    Column {
        anchors.top: heading.bottom
        anchors.topMargin: Theme.spacing.s
        width: parent.width

        Repeater {
            model: widget.hidesTitles ? [] : widget.open.slice(0, widget.rows)

            MouseArea {
                id: task

                required property var modelData

                width: parent.width
                height: Theme.font.normal * 2
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
            visible: !widget.hidesTitles && (widget.open.length > widget.rows || widget.open.length === 0)
            text: widget.open.length === 0 ? (Planner.todos.length > 0 ? "All done" : "Nothing to do")
                : "+" + (widget.open.length - widget.rows) + " more"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: widget.open.length === 0 ? Theme.font.large : Theme.font.small
        }
    }

    // On the lock screen: only how many, large, like the notifications widget.
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
            text: widget.open.length === 0 ? (Planner.todos.length > 0 ? "All done" : "Nothing to do")
                : widget.open.length === 1 ? "Task open" : "Tasks open"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            elide: Text.ElideRight
        }
    }
}
