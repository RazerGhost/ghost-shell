import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.theme
import qs.widgets

// What to customize, a key away (Super+U, `qs ipc call customize menu`; user's request instead
// of searching the launcher or going through Settings): a card over the dimmed screen with a
// tile per editor. Made for the keyboard: the arrow keys move, 1-5 jump straight to one, Enter
// or Space opens it, Escape or a click outside closes; the keys are shown under the tiles.
Scope {
    id: root

    property bool open: false

    // "lock", "desktop", "dock", "windows" or "quick" (Customize.qml opens it).
    signal picked(string id)

    readonly property var choices: [
        { id: "lock", icon: "lock", title: "Lock screen", text: "Clock, picture and widgets" },
        { id: "desktop", icon: "wallpaper", title: "Desktop", text: "Wallpaper, colors, widgets and themes" },
        { id: "dock", icon: "dock_to_bottom", title: "Dock and island", text: "What the island shows, the dock" },
        { id: "windows", icon: "select_window", title: "Windows", text: "Borders, gaps and motion" },
        { id: "quick", icon: "tune", title: "Quick settings", text: "Your tiles and buttons, in your order" }
    ]

    function toggle(): void {
        open = !open;
    }

    function pick(index: int): void {
        open = false;
        root.picked(choices[index].id);
    }

    PanelWindow {
        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-customize-menu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        BackgroundEffect.blurRegion: Region { item: card; radius: card.radius }

        // The first tile has the keyboard as soon as it opens.
        onVisibleChanged: {
            if (visible)
                tiles.itemAt(0)?.forceActiveFocus(Qt.TabFocusReason);
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.scrim

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }
        }

        Surface {
            id: card

            anchors.centerIn: parent
            width: content.implicitWidth + Theme.spacing.l * 3
            height: content.implicitHeight + Theme.spacing.l * 3
            radius: Theme.radius.xl

            // Clicks on the card stay on it.
            MouseArea {
                anchors.fill: parent
            }

            Keys.onEscapePressed: root.open = false
            Keys.onPressed: event => {
                const number = event.key - Qt.Key_1;
                if (number >= 0 && number < root.choices.length && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
                    root.pick(number);
                    event.accepted = true;
                    return;
                }
                const keys = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down];
                if (keys.includes(event.key))
                    event.accepted = navigation.move(event.key);
            }

            ArrowNavigation {
                id: navigation
                area: card
            }

            Column {
                id: content

                anchors.centerIn: parent
                spacing: Theme.spacing.l

                Column {
                    spacing: Theme.spacing.xs

                    Text {
                        text: "Customize"
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.title
                        font.weight: Font.DemiBold
                        Accessible.role: Accessible.Heading
                        Accessible.name: text
                    }

                    Text {
                        text: "Change it on the screen itself; every change shows at once."
                        color: Colors.m3onSurfaceVariant
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.normal
                    }
                }

                Row {
                    spacing: Theme.spacing.m

                    Repeater {
                        id: tiles
                        model: root.choices

                        Rectangle {
                            id: tile

                            required property var modelData
                            required property int index
                            readonly property bool lit: activeFocus || mouse.containsMouse

                            width: Theme.editor.menuTile
                            height: tileContent.implicitHeight + Theme.spacing.l * 2
                            radius: Theme.radius.l
                            color: lit ? Colors.m3primaryContainer : Colors.tint
                            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.title + ": " + modelData.text
                            Accessible.onPressAction: root.pick(index)
                            activeFocusOnTab: true
                            Keys.onReturnPressed: root.pick(index)
                            Keys.onEnterPressed: root.pick(index)
                            Keys.onSpacePressed: root.pick(index)

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pick(tile.index)
                            }

                            FocusRing {
                                radius: tile.radius
                            }

                            // Its number: the key that opens it.
                            KeyCap {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Theme.spacing.s
                                text: tile.index + 1
                            }

                            Column {
                                id: tileContent

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.spacing.l
                                spacing: Theme.spacing.s

                                Rectangle {
                                    width: Theme.icon.normal * 2.4
                                    height: width
                                    radius: width / 2
                                    color: tile.lit ? Colors.m3primary : Colors.m3surfaceContainerHighest
                                    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        icon: tile.modelData.icon
                                        color: tile.lit ? Colors.m3onPrimary : Colors.m3onSurface
                                        font.pixelSize: Theme.icon.normal * 1.2
                                    }
                                }

                                Text {
                                    width: parent.width
                                    topPadding: Theme.spacing.xs
                                    text: tile.modelData.title
                                    color: tile.lit ? Colors.m3onPrimaryContainer : Colors.m3onSurface
                                    font.family: Theme.font.sans
                                    font.pixelSize: Theme.font.large
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    // Two lines in every tile, so they're the same height.
                                    height: Theme.font.small * 2.8
                                    text: tile.modelData.text
                                    color: tile.lit ? Colors.m3onPrimaryContainer : Colors.m3onSurfaceVariant
                                    font.family: Theme.font.sans
                                    font.pixelSize: Theme.font.small
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // The keys.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacing.l
                    opacity: 0.8

                    Repeater {
                        model: [
                            { keys: ["←", "→"], label: "Move" },
                            { keys: ["Enter"], label: "Open" },
                            { keys: ["1–5"], label: "Jump to one" },
                            { keys: ["Esc"], label: "Close" }
                        ]

                        Row {
                            id: hint
                            required property var modelData
                            spacing: Theme.spacing.xs

                            Repeater {
                                model: hint.modelData.keys

                                KeyCap {
                                    required property string modelData
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                leftPadding: Theme.spacing.xs
                                text: hint.modelData.label
                                color: Colors.m3onSurfaceVariant
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.small
                            }
                        }
                    }
                }
            }
        }
    }
}
