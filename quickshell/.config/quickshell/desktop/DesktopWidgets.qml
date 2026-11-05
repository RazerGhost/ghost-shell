import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import "DesktopWidgets.js" as DesktopWidgetsJs

// Widgets on the wallpaper (the desktop editor's Widgets tab): a clock, the weather, the media
// player (with nothing playing, it offers the music app last heard), the calendar's next events,
// the battery, the to-do list, the timer, how many notifications wait, the next hours' weather,
// the month and a larger to-do list (ClockWidget, WeatherWidget, MediaWidget, CalendarWidget,
// BatteryWidget, TasksWidget for both to-dos, TimerWidget, NotificationsWidget, ForecastWidget,
// MonthWidget, NoteWidget, ClipboardWidget: one family of sizes; the list of them is DesktopWidgets.js's `kinds`). On the main screen, and on any other screen a widget was dropped onto (DesktopWidgets.screenOf; each screen its own layer and stage), on the layer just above the wallpaper, so windows cover them.
// Each can be dragged by its handle (DesktopCard.qml). The widgets themselves are WidgetStage.qml,
// which the lock screen draws too.
Scope {
    id: root

    readonly property bool any: DesktopWidgetsJs.keys.some(key => Settings.values[key])

    // The keyboard mode (Super+D, `qs ipc call widgets browse`; WidgetStage.browsing): like
    // Windows' "show desktop", from a workspace with windows it goes to an empty one first
    // (Editing's trip, which the editors use), and back when it ends.
    property bool browsing: false
    property bool tripped: false

    function browse(): void {
        if (browsing) {
            stopBrowsing(true);
            return;
        }
        // Not while locked, in focus mode (no widgets), or while an editor is away from your
        // workspace: the trip would take over its way home.
        if (!shown || Session.locked || Editing.desktop || Editing.awayFrom !== 0 || Editing.backPending)
            return;
        tripped = (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) > 0;
        if (tripped)
            Editing.toEmptyWorkspace();
        browsing = true;
    }

    // `goBack`: false when a widget handed you to something else on this workspace (the music
    // app it opened, the today menu).
    function stopBrowsing(goBack: bool): void {
        if (!browsing)
            return;
        browsing = false;
        if (tripped && goBack)
            Editing.back();
        tripped = false;
    }

    // Shown: some widget is on, and not hidden by focus mode (except in the desktop editor).
    readonly property bool shown: any && (!Focus.on || Editing.desktop)
    // The layer going away (focus mode starting) ends the keyboard mode with it.
    onShownChanged: {
        if (!shown)
            stopBrowsing(true);
    }

    IpcHandler {
        target: "widgets"

        function browse(): void {
            root.browse();
        }
    }

    // The screens with widgets: the main one, and any a widget was dropped onto.
    readonly property var screens: Quickshell.screens.filter(s => s === Screens.main
        || Object.values(Settings.values.desktopWidgets ?? {}).some(p => p?.screen === s.name))

    LazyLoader {
        // Hidden during focus mode (services/Focus.qml), except in the desktop editor.
        active: root.shown

        Variants {
            model: root.screens

            PanelWindow {
                id: window

                required property ShellScreen modelData
                readonly property bool main: modelData === Screens.main
                screen: modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "qs-desktop"
                // No keyboard, except while the to-do list's field is typed in: Exclusive takes it
                // (OnDemand alone doesn't until the pointer moves), then OnDemand keeps it until a
                // click elsewhere (verified on a Bottom layer, NOTES).
                WlrLayershell.keyboardFocus: widgetStage.keyboard === "take" ? WlrKeyboardFocus.Exclusive
                                           : widgetStage.keyboard === "keep" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                // Input and blur only on the widgets; the rest of the desktop stays click-through.
                mask: Region {
                    WidgetRegion { stage: widgetStage; widget: widgetStage.clockCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.weatherCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.mediaCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.calendarCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.batteryCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.todoCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.timerCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.notificationsCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.forecastCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.monthCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.tasksCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.noteCard }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.clipboardCard }
                }

                BackgroundEffect.blurRegion: Region {
                    WidgetRegion { stage: widgetStage; widget: widgetStage.clockCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.weatherCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.mediaCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.calendarCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.batteryCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.todoCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.timerCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.notificationsCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.forecastCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.monthCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.tasksCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.noteCard; corner: Theme.desktop.radius }
                    WidgetRegion { stage: widgetStage; widget: widgetStage.clipboardCard; corner: Theme.desktop.radius }
                    // Never empty: Hyprland 0.57 blurs the whole surface for an empty region (NOTES).
                    Region { width: 1; height: 1 }
                }

                // The widgets' area: the whole screen, or scaled into the card the wallpaper is drawn
                // as while the desktop editor is open (services/Editing.qml).
                WidgetStage {
                    id: widgetStage

                    screenName: window.modelData?.name ?? ""
                    // The keyboard mode (Super+D) is the main screen's widgets.
                    browsing: root.browsing && window.main
                    onLeave: goBack => root.stopBrowsing(goBack)

                    readonly property bool carded: Editing.cardScreen === (window.screen?.name ?? "")

                    width: window.width
                    height: window.height
                    x: carded ? Editing.card.x : 0
                    y: carded ? Editing.card.y : 0
                    scale: carded ? Editing.card.width / Math.max(window.width, 1) : 1
                    transformOrigin: Item.TopLeft

                    Behavior on x { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
                    Behavior on y { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
                    Behavior on scale { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
                }
            }
        }
    }
}
