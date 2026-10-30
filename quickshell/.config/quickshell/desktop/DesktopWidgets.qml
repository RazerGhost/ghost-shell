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
// Each can be dragged by its handle (DesktopCard.qml).
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
                WidgetRegion { stage: widgetStage; widget: clockCard }
                WidgetRegion { stage: widgetStage; widget: weatherCard }
                WidgetRegion { stage: widgetStage; widget: mediaCard }
                WidgetRegion { stage: widgetStage; widget: calendarCard }
                WidgetRegion { stage: widgetStage; widget: batteryCard }
                WidgetRegion { stage: widgetStage; widget: todoCard }
                WidgetRegion { stage: widgetStage; widget: timerCard }
            }

            BackgroundEffect.blurRegion: Region {
                WidgetRegion { stage: widgetStage; widget: clockCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: weatherCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: mediaCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: calendarCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: batteryCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: todoCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: timerCard; corner: Theme.desktop.radius }
                // Never empty: Hyprland 0.57 blurs the whole surface for an empty region (NOTES).
                Region { width: 1; height: 1 }
            }

            // The widgets' area: the whole screen, or scaled into the card the wallpaper is drawn
            // as while the desktop editor is open (customize/Editing.qml).
            Item {
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

                // The grid, while it's on and the widgets are being placed (the desktop editor, a
                // drag): faint lines out from the middle, the middle ones stronger.
                Item {
                    id: grid

                    readonly property real cell: Theme.px(DesktopWidgetsJs.gridSize(Settings.values.desktopGridSize))
                    readonly property bool placing: Editing.desktop || [clockCard, weatherCard, mediaCard, calendarCard,
                                                                        batteryCard, todoCard, timerCard].some(c => c.moving)

                    anchors.fill: parent
                    opacity: Settings.values.desktopGrid && placing ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }

                    Repeater {
                        model: grid.visible ? DesktopWidgetsJs.gridLines(widgetStage.width, grid.cell) : []

                        Rectangle {
                            required property real modelData
                            readonly property bool middle: Math.abs(modelData - widgetStage.width / 2) < 0.5
                            // One screen pixel (two for the middle) at any scale: in the editor's
                            // card a 1 px line shrank below a pixel and some faded out.
                            x: modelData - width / 2
                            width: (middle ? 2 : 1) / widgetStage.scale
                            height: grid.height
                            color: Colors.sketch
                            opacity: middle ? 0.8 : 0.3
                        }
                    }

                    Repeater {
                        model: grid.visible ? DesktopWidgetsJs.gridLines(widgetStage.height, grid.cell) : []

                        Rectangle {
                            required property real modelData
                            readonly property bool middle: Math.abs(modelData - widgetStage.height / 2) < 0.5
                            y: modelData - height / 2
                            width: grid.width
                            height: (middle ? 2 : 1) / widgetStage.scale
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

                    WeatherWidget {}
                }

                DesktopCard {
                    id: mediaCard
                    name: "media"
                    shown: Settings.values.desktopMedia

                    MediaWidget {}
                }

                DesktopCard {
                    id: calendarCard
                    name: "calendar"
                    shown: Settings.values.desktopCalendar

                    CalendarWidget {}
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

                    TodoWidget {}
                }

                DesktopCard {
                    id: timerCard
                    name: "timer"
                    shown: Settings.values.desktopTimer

                    TimerWidget {}
                }
            }
        }
    }
}
