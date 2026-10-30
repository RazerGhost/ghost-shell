import QtQuick
import qs.controlcenter
import qs.services
import qs.theme
import "LockClock.js" as LockClockJs
import "LockWidgets.js" as LockWidgets

// Under the clock on the lock screen (not the login screen): the media player, like the
// island's small one, and a row of round widgets, like iOS's (LockWidget.qml: weather, battery,
// notifications, to-dos, the next event), both picked in the lock screen editor.
Column {
    id: root

    readonly property var widgets: LockWidgets.shown(Settings.values.lockWidgets, Settings.values)
    // What it covers across (the lock screen editor outlines it): the row of widgets can be wider
    // than the column, or narrower without the player.
    readonly property real contentX: media.visible ? Math.min(0, row.x) : row.x
    readonly property real contentWidth: media.visible ? Math.max(width, row.width) : row.width

    spacing: Theme.spacing.l

    MediaCard {
        id: media
        width: parent.width
        visible: Settings.values.lockMedia && player !== null
    }

    Row {
        id: row
        // Lined up with the clock: from the left in the bottom-left layout, else centered.
        x: LockClockJs.pick(Settings.values.lockLayout, LockClockJs.layouts) === "left" ? 0 : (parent.width - width) / 2
        spacing: Theme.lock.widgetGap

        Repeater {
            model: root.widgets

            LockWidget {
                required property string modelData
                kind: modelData
            }
        }
    }
}
