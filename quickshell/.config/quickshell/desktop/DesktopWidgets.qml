import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets
import "DesktopWidgets.js" as DesktopWidgetsJs

// Widgets on the wallpaper (the desktop editor's Widgets tab): a clock, the weather, the
// media player (with nothing playing, it offers the music app last heard), the calendar's next events, the battery, the to-do list
// and the timer (ClockWidget, WeatherWidget, MediaWidget, CalendarWidget, BatteryWidget,
// TodoWidget, TimerWidget: one family of sizes; the list of them is DesktopWidgets.js's
// `kinds`). On the first screen, on the layer just above the wallpaper, so windows cover them.
// Each can be dragged by its handle (DesktopCard.qml). The widgets themselves are WidgetStage.qml,
// which the lock screen draws too.
Scope {
    id: root

    readonly property bool any: DesktopWidgetsJs.keys.some(key => Settings.values[key])

    LazyLoader {
        active: root.any

        PanelWindow {
            id: window

            screen: Quickshell.screens[0] ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "qs-desktop"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Input and blur only on the widgets; the rest of the desktop stays click-through.
            mask: Region {
                WidgetRegion { stage: widgetStage; widget: widgetStage.clockCard }
                WidgetRegion { stage: widgetStage; widget: widgetStage.weatherCard }
                WidgetRegion { stage: widgetStage; widget: widgetStage.mediaCard }
                WidgetRegion { stage: widgetStage; widget: widgetStage.calendarCard }
                WidgetRegion { stage: widgetStage; widget: widgetStage.batteryCard }
                WidgetRegion { stage: widgetStage; widget: widgetStage.todoCard }
                WidgetRegion { stage: widgetStage; widget: widgetStage.timerCard }
            }

            BackgroundEffect.blurRegion: Region {
                WidgetRegion { stage: widgetStage; widget: widgetStage.clockCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: widgetStage.weatherCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: widgetStage.mediaCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: widgetStage.calendarCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: widgetStage.batteryCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: widgetStage.todoCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: widgetStage.timerCard; corner: Theme.desktop.radius }
                // Never empty: Hyprland 0.57 blurs the whole surface for an empty region (NOTES).
                Region { width: 1; height: 1 }
            }

            // The widgets' area: the whole screen, or scaled into the card the wallpaper is drawn
            // as while the desktop editor is open (customize/Editing.qml).
            WidgetStage {
                id: widgetStage

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
