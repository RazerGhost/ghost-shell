import QtQuick
import qs.controlcenter
import qs.services
import qs.theme
import "LockClock.js" as LockClockJs
import "LockWidgets.js" as LockWidgets

// Under the clock on the lock screen (not the login screen): the media player, like the
// island's small one, and a row of round widgets, like iOS's (LockWidget.qml: weather, battery,
// notifications, to-dos, the timer, the next event), picked in the lock screen editor. The
// player and each widget have their own place there, dragged like the clock (PartShift.qml).
Column {
    id: root

    // The LockContent it's under (its places and the editor's outlines).
    required property Item lock

    // Not the battery on a machine without one.
    readonly property var widgets: LockWidgets.shown(Settings.values.lockWidgets, Settings.values)
        .filter(id => !id.startsWith("battery") || Battery.present)
    spacing: Theme.spacing.l

    // The player, in a holder that stays enabled: in the editor the card takes no input, and
    // its outline beside it still has to (a disabled parent disables its children).
    Item {
        id: player
        width: parent.width
        height: media.height
        visible: Settings.values.lockMedia && Media.player !== null
        transform: PartShift { content: root.lock; name: "player"; target: player }

        MediaCard {
            id: media
            width: parent.width
            enabled: root.lock.editor === null
        }

        PartOutline { content: root.lock; part: "player"; target: player; tab: "widgets"; name: "The player" }
    }

    Row {
        id: row
        // Lined up with the clock: from the left in the bottom-left layout, else centered.
        x: LockClockJs.pick(Settings.values.lockLayout, LockClockJs.layouts) === "left" ? 0 : (parent.width - width) / 2
        spacing: Theme.lock.widgetGap

        Repeater {
            model: root.widgets

            LockWidget {
                id: widget
                required property string modelData
                kind: modelData
                transform: PartShift { content: root.lock; name: widget.modelData; target: widget }

                PartOutline {
                    content: root.lock
                    part: widget.modelData
                    target: widget
                    tab: "widgets"
                    name: "The " + widget.modelData + " widget"
                    radius: height / 2
                }
            }
        }
    }
}
