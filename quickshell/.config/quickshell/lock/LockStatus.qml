import QtQuick
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets

// Under the clock on the lock screen (not the login screen): the media player, like the island's
// small one, the weather, the battery, the next calendar event, and how many notifications came
// in, never what they say (anyone can read a locked screen). Each is a switch in Settings ->
// Lock screen.
Column {
    spacing: Theme.spacing.m

    MediaCard {
        width: parent.width
        visible: Settings.values.lockMedia && player !== null
    }

    // Weather, battery and the next event, each a switch in Settings -> Lock screen. The event
    // is off by default: its title would show to anyone at the locked screen.
    LockLine {
        visible: Settings.values.lockWeather && Weather.current !== null
        icon: Weather.current?.icon ?? ""
        text: Weather.current ? `${Weather.current.temperature}° ${Weather.current.label}` : ""
    }

    LockLine {
        visible: Settings.values.lockBattery && Battery.present
        icon: Battery.icon
        text: Math.round(Battery.level * 100) + " %" + (Battery.timeLabel ? " · " + Battery.timeLabel : "")
    }

    LockLine {
        readonly property var next: Agenda.upcoming[0] ?? null
        visible: Settings.values.lockEvent && next !== null
        icon: "event"
        text: next ? Agenda.when(next) + " · " + next.title : ""
    }

    LockLine {
        readonly property int count: Notifications.history.length
        visible: Settings.values.lockNotificationCount && count > 0
        icon: "notifications"
        text: count === 1 ? "1 notification" : count + " notifications"
    }
}
