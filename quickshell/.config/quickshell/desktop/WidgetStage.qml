import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "DesktopWidgets.js" as DesktopWidgetsJs

// The desktop widgets at their places (the desktop editor's Widgets tab), drawn by the desktop
// (DesktopWidgets.qml) and the lock screen (lock/LockContent.qml), which shows the desktop
// locked. `locked`: no handles or grid, only the media widget's playback buttons take clicks,
// the calendar and to-do widgets keep their titles to themselves and the weather your town
// (anyone at the locked screen can see it).
Item {
    id: stage

    property bool locked: false
    // The screen whose widgets show here ("": all of them, the editor's gallery).
    property string screenName: ""

    readonly property alias clockCard: clockCard
    readonly property alias weatherCard: weatherCard
    readonly property alias mediaCard: mediaCard
    readonly property alias calendarCard: calendarCard
    readonly property alias batteryCard: batteryCard
    readonly property alias todoCard: todoCard
    readonly property alias timerCard: timerCard
    readonly property alias notificationsCard: notificationsCard
    readonly property alias forecastCard: forecastCard
    readonly property alias monthCard: monthCard
    readonly property alias tasksCard: tasksCard
    readonly property alias noteCard: noteCard
    readonly property alias clipboardCard: clipboardCard
    readonly property var cards: [clockCard, weatherCard, mediaCard, calendarCard, batteryCard, todoCard, timerCard,
                                  notificationsCard, forecastCard, monthCard, tasksCard, noteCard, clipboardCard]
    // A to-do widget's field or the note is being typed in: the desktop's layer takes the keyboard meanwhile
    // ("take" until it has it, then "keep"; DesktopWidgets.qml), else "none".
    readonly property var typists: [todoWidget.keyboard, tasksWidget.keyboard, noteWidget.keyboard]
    readonly property var typing: typists.find(k => k.wantsKeyboard) ?? null
    // One field at a time: starting in one ends the others' typing.
    function only(keyboard: var): void {
        for (const other of typists)
            if (other !== keyboard && other.wantsKeyboard)
                other.stop();
    }

    Connections {
        target: todoWidget.keyboard
        function onWantsKeyboardChanged(): void {
            if (todoWidget.keyboard.wantsKeyboard)
                stage.only(todoWidget.keyboard);
        }
    }

    Connections {
        target: tasksWidget.keyboard
        function onWantsKeyboardChanged(): void {
            if (tasksWidget.keyboard.wantsKeyboard)
                stage.only(tasksWidget.keyboard);
        }
    }

    Connections {
        target: noteWidget.keyboard
        function onWantsKeyboardChanged(): void {
            if (noteWidget.keyboard.wantsKeyboard)
                stage.only(noteWidget.keyboard);
        }
    }

    readonly property string keyboard: !typing ? "none" : typing.hasKeyboard ? "keep" : "take"

    // Where each widget showing goes at the shell's size, groups kept together
    // (DesktopWidgets.arrange); DesktopCard reads its own.
    readonly property var arranged: DesktopWidgetsJs.arrange(
        cards.filter(c => c.shown).map(c => ({ name: c.name, x: c.spot.x, y: c.spot.y, w: c.width, h: c.height })),
        width, height, Theme.desktop.zoom, Theme.desktop.gap * 2)

    // The grid, while it's on and the widgets are being placed (the desktop editor, a drag):
    // faint lines out from the middle, the middle ones stronger.
    Item {
        id: grid

        readonly property real cell: Theme.px(DesktopWidgetsJs.gridSize(Settings.values.desktopGridSize))
        readonly property bool placing: !stage.locked && (Editing.desktop || stage.cards.some(c => c.moving))

        anchors.fill: parent
        opacity: Settings.values.desktopGrid && placing ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }

        Repeater {
            model: grid.visible ? DesktopWidgetsJs.gridLines(stage.width, grid.cell) : []

            Rectangle {
                required property real modelData
                readonly property bool middle: Math.abs(modelData - stage.width / 2) < 0.5
                // One screen pixel (two for the middle) at any scale: in the editor's card a 1 px
                // line shrank below a pixel and some faded out.
                x: modelData - width / 2
                width: (middle ? 2 : 1) / stage.scale
                height: grid.height
                color: Colors.sketch
                opacity: middle ? 0.8 : 0.3
            }
        }

        Repeater {
            model: grid.visible ? DesktopWidgetsJs.gridLines(stage.height, grid.cell) : []

            Rectangle {
                required property real modelData
                readonly property bool middle: Math.abs(modelData - stage.height / 2) < 0.5
                y: modelData - height / 2
                width: grid.width
                height: (middle ? 2 : 1) / stage.scale
                color: Colors.sketch
                opacity: middle ? 0.8 : 0.3
            }
        }
    }

    DesktopCard {
        id: clockCard
        name: "clock"
        wanted: Settings.values.desktopClock

        ClockWidget {}
    }

    DesktopCard {
        id: weatherCard
        name: "weather"
        wanted: Settings.values.desktopWeather

        WeatherWidget {
            hidesPlace: stage.locked
        }
    }

    DesktopCard {
        id: mediaCard
        name: "media"
        wanted: Settings.values.desktopMedia

        MediaWidget {
            locked: stage.locked
        }
    }

    DesktopCard {
        id: calendarCard
        name: "calendar"
        wanted: Settings.values.desktopCalendar

        CalendarWidget {
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: batteryCard
        name: "battery"
        wanted: Settings.values.desktopBattery && Battery.present

        BatteryWidget {}
    }

    DesktopCard {
        id: todoCard
        name: "todo"
        wanted: Settings.values.desktopTodo

        TasksWidget {
            id: todoWidget
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: timerCard
        name: "timer"
        wanted: Settings.values.desktopTimer

        TimerWidget {}
    }

    DesktopCard {
        id: notificationsCard
        name: "notifications"
        wanted: Settings.values.desktopNotifications

        NotificationsWidget {
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: forecastCard
        name: "forecast"
        wanted: Settings.values.desktopForecast

        ForecastWidget {}
    }

    DesktopCard {
        id: monthCard
        name: "month"
        wanted: Settings.values.desktopMonth

        MonthWidget {
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: tasksCard
        name: "tasks"
        wanted: Settings.values.desktopTasks

        TasksWidget {
            id: tasksWidget
            large: true
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: noteCard
        name: "note"
        wanted: Settings.values.desktopNote

        NoteWidget {
            id: noteWidget
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: clipboardCard
        name: "clipboard"
        wanted: Settings.values.desktopClipboard

        ClipboardWidget {
            hidesTitles: stage.locked
        }
    }
}
