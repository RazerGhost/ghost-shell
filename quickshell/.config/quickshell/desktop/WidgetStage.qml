import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "DesktopWidgets.js" as DesktopWidgetsJs
import "../widgets/ArrowNavigation.js" as ArrowNavigationJs

// The desktop widgets at their places (the desktop editor's Widgets tab), drawn by the desktop
// (DesktopWidgets.qml) and the lock screen (lock/LockContent.qml), which shows the desktop
// locked. `locked`: no handles or grid, only the media widget's playback buttons take clicks,
// the calendar and to-do widgets keep their titles to themselves and the weather your town
// (anyone at the locked screen can see it).
Item {
    id: stage

    property bool locked: false

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
    readonly property var typists: [todoWidget.keyboard, tasksWidget.keyboard, noteWidget.keyboard, browser]
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
        function onStopped(): void {
            stage.typed(todoWidget.keyboard);
        }
    }

    Connections {
        target: tasksWidget.keyboard
        function onWantsKeyboardChanged(): void {
            if (tasksWidget.keyboard.wantsKeyboard)
                stage.only(tasksWidget.keyboard);
        }
        function onStopped(): void {
            stage.typed(tasksWidget.keyboard);
        }
    }

    Connections {
        target: noteWidget.keyboard
        function onWantsKeyboardChanged(): void {
            if (noteWidget.keyboard.wantsKeyboard)
                stage.only(noteWidget.keyboard);
        }
        function onStopped(): void {
            stage.typed(noteWidget.keyboard);
        }
    }

    // The keyboard mode (Super+D, DesktopWidgets.qml): the widgets take the keyboard, the arrow
    // keys move between them (to the nearest that way, ArrowNavigation.js), Tab in reading
    // order, and the chosen one gets the keys first (WidgetSurface.key: rows in the to-do and
    // clipboard widgets, Enter to type, copy, play or start). Typing in a field from here comes
    // back here after Escape; Escape here, or a click outside the widgets, ends it (`leave`).
    property bool browsing: false
    signal leave()
    property Item chosenCard: null
    readonly property var shownCards: cards.filter(c => c.shown && c.widget)

    onBrowsingChanged: {
        if (browsing) {
            if (!chosenCard || !chosenCard.shown)
                chosenCard = shownCards[ArrowNavigationJs.nearest(null, shownCards.map(rectOf), "down")] ?? null;
            browser.start();
        } else {
            if (browser.wantsKeyboard)
                browser.stop();
            chosenCard = null;
        }
        markChosen();
    }
    onChosenCardChanged: markChosen()

    function markChosen(): void {
        for (const card of cards)
            card.chosen = browsing && card === chosenCard;
    }

    function rectOf(card: Item): var {
        const at = card.mapToItem(stage, 0, 0);
        return { x: at.x, y: at.y, width: card.width, height: card.height };
    }

    // A field's typing ended: back to the keyboard mode after Escape or Enter, out of it after
    // a click elsewhere.
    function typed(keyboard: var): void {
        if (!browsing || typing)
            return;
        if (keyboard.released)
            leave();
        else
            Qt.callLater(browser.start);
    }

    function press(event: var): void {
        if (chosenCard?.widget?.key(event)) {
            event.accepted = true;
            return;
        }
        const directions = { [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down" };
        const rects = shownCards.map(rectOf);
        if (event.key in directions) {
            const next = ArrowNavigationJs.nearest(chosenCard ? rectOf(chosenCard) : null, rects, directions[event.key]);
            if (next >= 0)
                chosenCard = shownCards[next];
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            const order = shownCards.slice().sort((a, b) => rectOf(a).y - rectOf(b).y || rectOf(a).x - rectOf(b).x);
            const step = event.key === Qt.Key_Tab ? 1 : order.length - 1;
            chosenCard = order[(order.indexOf(chosenCard) + step) % order.length] ?? null;
        } else if (event.key === Qt.Key_Escape) {
            leave();
        } else {
            return;
        }
        event.accepted = true;
    }

    WidgetKeyboard {
        id: browser
        onHasKeyboardChanged: {
            if (hasKeyboard)
                navigator.forceActiveFocus();
        }
        onStopped: {
            if (released)
                stage.leave();
        }
    }

    Item {
        id: navigator
        Keys.onPressed: event => stage.press(event)
        Accessible.role: Accessible.Pane
        Accessible.name: "Desktop widgets" + (stage.chosenCard ? ": " + stage.chosenCard.name : "")
    }

    // What the keys do, at the foot of the screen while the keyboard mode is on.
    WidgetSurface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.desktop.margin
        width: hints.implicitWidth + Theme.desktop.padding * 2
        height: hints.implicitHeight + Theme.desktop.padding * 2
        visible: stage.browsing && !stage.locked

        KeyHints {
            id: hints
            anchors.centerIn: parent
            hints: [
                { keys: ["←", "→", "↑", "↓"], label: "Move" },
                { keys: ["Enter"], label: "Use" },
                { keys: ["Esc"], label: "Done" }
            ]
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
        shown: Settings.values.desktopClock

        ClockWidget {}
    }

    DesktopCard {
        id: weatherCard
        name: "weather"
        shown: Settings.values.desktopWeather

        WeatherWidget {
            hidesPlace: stage.locked
        }
    }

    DesktopCard {
        id: mediaCard
        name: "media"
        shown: Settings.values.desktopMedia

        MediaWidget {
            locked: stage.locked
        }
    }

    DesktopCard {
        id: calendarCard
        name: "calendar"
        shown: Settings.values.desktopCalendar

        CalendarWidget {
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: batteryCard
        name: "battery"
        shown: Settings.values.desktopBattery && Battery.present

        BatteryWidget {}
    }

    DesktopCard {
        id: todoCard
        name: "todo"
        shown: Settings.values.desktopTodo

        TasksWidget {
            id: todoWidget
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: timerCard
        name: "timer"
        shown: Settings.values.desktopTimer

        TimerWidget {}
    }

    DesktopCard {
        id: notificationsCard
        name: "notifications"
        shown: Settings.values.desktopNotifications

        NotificationsWidget {}
    }

    DesktopCard {
        id: forecastCard
        name: "forecast"
        shown: Settings.values.desktopForecast

        ForecastWidget {}
    }

    DesktopCard {
        id: monthCard
        name: "month"
        shown: Settings.values.desktopMonth

        MonthWidget {
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: tasksCard
        name: "tasks"
        shown: Settings.values.desktopTasks

        TasksWidget {
            id: tasksWidget
            large: true
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: noteCard
        name: "note"
        shown: Settings.values.desktopNote

        NoteWidget {
            id: noteWidget
            hidesTitles: stage.locked
        }
    }

    DesktopCard {
        id: clipboardCard
        name: "clipboard"
        shown: Settings.values.desktopClipboard

        ClipboardWidget {
            hidesTitles: stage.locked
        }
    }
}
