import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// Widgets on the wallpaper (the desktop editor's Widgets tab): a clock, the weather, and the
// media player while something plays (ClockWidget, WeatherWidget, MediaWidget: one family of
// sizes). On the first screen, on the layer just above the wallpaper, so windows cover them.
// Each can be dragged by its handle (DesktopCard.qml).
Scope {
    id: root

    readonly property bool any: Settings.values.desktopClock || Settings.values.desktopWeather
                                || Settings.values.desktopMedia

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
            }

            BackgroundEffect.blurRegion: Region {
                WidgetRegion { stage: widgetStage; widget: clockCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: weatherCard; corner: Theme.desktop.radius }
                WidgetRegion { stage: widgetStage; widget: mediaCard; corner: Theme.desktop.radius }
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
                scale: carded ? Editing.card.width / window.width : 1
                transformOrigin: Item.TopLeft

                Behavior on x { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
                Behavior on y { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
                Behavior on scale { NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }

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
                    shown: Settings.values.desktopMedia && Media.player !== null

                    MediaWidget {}
                }
            }
        }
    }
}
