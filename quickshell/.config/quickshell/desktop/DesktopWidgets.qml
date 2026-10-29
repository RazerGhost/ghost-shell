import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.controlcenter
import qs.services
import qs.theme
import qs.widgets

// Widgets on the wallpaper (Settings -> Appearance -> Desktop widgets): a clock, the weather,
// and the media player while something plays. On the first screen, on the layer just above the
// wallpaper, so windows cover them. Each can be dragged by its handle (DesktopCard.qml).
Scope {
    id: root

    readonly property bool any: Settings.values.desktopClock || Settings.values.desktopWeather
                                || Settings.values.desktopMedia

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

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
                Region { item: clockCard.visible ? clockCard : null }
                Region { item: weatherCard.visible ? weatherCard : null }
                Region { item: mediaCard.visible ? mediaCard : null }
            }

            BackgroundEffect.blurRegion: Region {
                Region { item: clockCard.visible ? clockCard : null; radius: Theme.radius.l }
                Region { item: weatherCard.visible ? weatherCard : null; radius: Theme.radius.l }
                Region { item: mediaCard.visible ? mediaCard : null; radius: Theme.radius.l }
                // Never empty: Hyprland 0.57 blurs the whole surface for an empty region (NOTES).
                Region { width: 1; height: 1 }
            }

            DesktopCard {
                id: clockCard
                name: "clock"
                visible: Settings.values.desktopClock

                Surface {
                    width: clockColumn.width + Theme.spacing.l * 2
                    height: clockColumn.height + Theme.spacing.l * 2
                    radius: Theme.radius.l

                    Column {
                        id: clockColumn
                        anchors.centerIn: parent

                        Text {
                            text: Qt.formatTime(clock.date, Settings.values.clock24Hour ? "HH:mm" : "h:mm AP")
                            color: Colors.m3onSurface
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.desktop.clock
                            font.weight: Font.Bold
                            font.features: { "tnum": 1 }
                        }

                        Text {
                            // English names even with Dutch regional formats, like the calendar.
                            text: Qt.locale(Qt.uiLanguage).toString(clock.date, "dddd, d MMMM")
                            color: Colors.m3onSurfaceVariant
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.title
                        }
                    }
                }
            }

            DesktopCard {
                id: weatherCard
                name: "weather"
                visible: Settings.values.desktopWeather && Weather.current !== null

                Surface {
                    width: Theme.desktop.width
                    height: weatherColumn.height + Theme.spacing.l * 2
                    radius: Theme.radius.l

                    Column {
                        id: weatherColumn
                        x: Theme.spacing.l
                        y: Theme.spacing.l
                        width: parent.width - Theme.spacing.l * 2
                        spacing: Theme.spacing.xs

                        Row {
                            spacing: Theme.spacing.m

                            MaterialIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: Weather.current?.icon ?? ""
                                color: Colors.m3primary
                                font.pixelSize: Theme.desktop.weather
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (Weather.current?.temperature ?? "") + "°"
                                color: Colors.m3onSurface
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.desktop.weather
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            width: parent.width
                            text: Weather.current ? `${Weather.current.label}  ·  ↑${Weather.current.high}° ↓${Weather.current.low}°` : ""
                            color: Colors.m3onSurface
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.normal
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: Weather.place?.name ?? Settings.values.weatherLocation
                            color: Colors.m3onSurfaceVariant
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            DesktopCard {
                id: mediaCard
                name: "media"
                visible: Settings.values.desktopMedia && Media.player !== null

                MediaCard {
                    width: Theme.desktop.width
                    color: Colors.surfaceTranslucent
                    border.width: Theme.glass.edge
                    border.color: Colors.glassEdge
                    onActivated: Media.show() // the player's window
                }
            }
        }
    }
}
