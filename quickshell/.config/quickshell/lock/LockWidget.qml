import QtQuick
import qs.services
import qs.theme
import qs.widgets

// One of the lock screen's widgets under the clock, like iOS's: round, on a translucent
// circle. Weather (its icon and temperature), battery (a ring with the percentage), how many
// notifications came in (never what they say) and to-dos are open, the timer (a ring emptying
// around the time left); the next event is wide, its
// time over its title. Picked in the lock screen editor (lock/LockWidgets.js).
Surface {
    id: root

    // "weather", "battery", "notifications", "todo", "timer" or "event"
    required property string kind
    readonly property var next: Agenda.upcoming[0] ?? null

    width: kind === "event" ? Theme.lock.widget * 2 + Theme.lock.widgetGap : Theme.lock.widget
    height: Theme.lock.widget
    radius: height / 2

    Accessible.role: Accessible.StaticText
    Accessible.name: kind === "weather" ? (Weather.current ? `${Weather.current.temperature}° ${Weather.current.label}` : "No weather yet")
                   : kind === "battery" ? "Battery " + Math.round(Battery.level * 100) + "%"
                   : kind === "notifications" ? Notifications.history.length + (Notifications.history.length === 1 ? " notification" : " notifications")
                   : kind === "todo" ? Planner.open + (Planner.open === 1 ? " to-do open" : " to-dos open")
                   : kind === "timer" ? (Countdown.active ? "Timer, " + Countdown.label + " left" : "No timer")
                   : next ? Agenda.when(next) + ", " + next.title : "No events"

    // An icon over a short value: weather, notifications, to-dos.
    Column {
        anchors.centerIn: parent
        visible: root.kind === "weather" || root.kind === "notifications" || root.kind === "todo"

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: root.kind === "weather" ? (Weather.current?.icon ?? "cloud_off")
                : root.kind === "notifications" ? "notifications" : "checklist"
            color: Colors.m3onSurfaceVariant
            font.pixelSize: Theme.icon.normal
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.kind === "weather" ? (Weather.current ? Weather.current.temperature + "°" : "–")
                : root.kind === "notifications" ? Notifications.history.length
                : Planner.open
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.large
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }

    ProgressRing {
        anchors.fill: parent
        anchors.margins: Theme.spacing.s
        visible: root.kind === "battery"
        value: Battery.level
        color: Battery.low ? Colors.m3error : Colors.m3onSurface
        lineWidth: Theme.lock.ringWidth

        Column {
            anchors.centerIn: parent

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Battery.charging
                icon: "bolt"
                color: Colors.m3onSurfaceVariant
                font.pixelSize: Theme.icon.small
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(Battery.level * 100)
                color: Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.large
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }
    }

    // The timer: idle, its icon; running, a ring emptying around the time left.
    MaterialIcon {
        anchors.centerIn: parent
        visible: root.kind === "timer" && !Countdown.active
        icon: "timer"
        color: Colors.m3onSurfaceVariant
        font.pixelSize: Theme.icon.normal
    }

    ProgressRing {
        anchors.fill: parent
        anchors.margins: Theme.spacing.s
        visible: root.kind === "timer" && Countdown.active
        value: Countdown.progress
        color: Countdown.paused ? Colors.m3onSurfaceVariant : Colors.m3onSurface
        lineWidth: Theme.lock.ringWidth

        Text {
            anchors.centerIn: parent
            width: parent.width - parent.lineWidth * 2
            horizontalAlignment: Text.AlignHCenter
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.font.small * 0.8
            text: Countdown.label
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }

    // The next event: when, then what.
    Column {
        visible: root.kind === "event"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.lock.widgetInset
        anchors.rightMargin: Theme.lock.widgetInset

        Text {
            width: parent.width
            text: root.next ? Agenda.when(root.next) : "Calendar"
            color: Colors.m3primary
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.next ? root.next.title : Agenda.enabled ? "No events" : "No calendar"
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }
}
