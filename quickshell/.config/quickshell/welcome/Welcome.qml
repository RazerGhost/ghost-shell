import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.widgets

// The welcome tour: a few cards over the dimmed screen on how this desktop works, shown the first
// time the shell starts (`welcomeSeen` in settings.json), and again from Settings -> Keybinds or
// `qs ipc call welcome show`. Right / Enter for the next card, Left for the previous, Escape skips.
Scope {
    id: root

    property bool open: false
    property int step: 0

    // The keys are the binds in hypr/binds.lua (each a list of key combinations).
    readonly property var steps: [
        { icon: "waving_hand", title: "Welcome to Ghost Shell",
          text: "A quick look at how this desktop works. It takes a minute; Escape skips it.",
          keys: [] },
        { icon: "search", title: "Open apps, windows and files",
          text: "Tap Super and type: apps and open windows. \"/ name\" finds files, \"> command\" runs one in the terminal, and sums and conversions work too: try \"5 km in miles\".",
          keys: [["Super"], ["Super", "Space"]] },
        { icon: "page_header", title: "The island",
          text: "The shape at the top of the screen. Click the time for the calendar, notifications, a to-do list, a note and a timer; click the icons next to it for quick settings: Wi-Fi, sound, game mode and more. The arrow at the far right shows apps running in the background.",
          keys: [["Super", "C"], ["Super", "N"]] },
        { icon: "view_quilt", title: "Windows arrange themselves",
          text: "New windows tile side by side. The window menu picks a layout or makes tabs; Alt + Tab switches, Super + Tab shows everything at once.",
          keys: [["Super", "Z"], ["Alt", "Tab"], ["Super", "Tab"]] },
        { icon: "dock_to_bottom", title: "The dock and handy tools",
          text: "Touch the bottom edge with the pointer for the dock. Clipboard history, emoji and screenshots are a key away, and a screenshot's notification lets you draw on it.",
          keys: [["Super", "V"], ["Super", "."], ["Super", "Shift", "S"]] },
        { icon: "terminal", title: "A terminal that drops down",
          text: "Super + ` brings a terminal down over everything and hides it again. Super + Shift + ` tucks any window away there, and brings it back.",
          keys: [["Super", "`"], ["Super", "Shift", "`"]] },
        { icon: "settings", title: "Everything else is in Settings",
          text: "Wallpaper, light or dark, display, sound, notifications per app, every keybind, and this tour again (under Keybinds).",
          keys: [["Super", "I"]] }
    ]
    readonly property var current: steps[step]
    readonly property bool last: step === steps.length - 1

    function show(): void {
        step = 0;
        open = true;
    }

    function close(): void {
        open = false;
        Settings.values.welcomeSeen = true;
    }

    function next(): void {
        if (last)
            close();
        else
            step++;
    }

    function previous(): void {
        if (step > 0)
            step--;
    }

    // The first start: once the settings are read, so a saved `welcomeSeen` counts.
    Connections {
        target: Settings

        function onLoadedChanged(): void {
            if (Settings.loaded && !Settings.values.welcomeSeen)
                root.show();
        }
    }

    IpcHandler {
        target: "welcome"

        function show(): void {
            root.show();
        }
    }

    PanelWindow {
        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "qs-welcome"

        // Blur behind the card, not the dimmed screen around it (ext-background-effect; see NOTES.md).
        BackgroundEffect.blurRegion: Region { item: card; radius: card.radius }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            if (visible)
                card.forceActiveFocus();
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.scrim
        }

        Surface {
            id: card

            anchors.centerIn: parent
            width: Theme.welcome.width
            height: content.implicitHeight + Theme.spacing.l * 2
            radius: Theme.radius.xl

            Accessible.role: Accessible.Dialog
            Accessible.name: root.current.title
            Accessible.description: root.current.text

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    root.next();
                else if (event.key === Qt.Key_Left)
                    root.previous();
                else if (event.key === Qt.Key_Escape)
                    root.close();
                else
                    return;
                event.accepted = true;
            }

            Column {
                id: content

                x: Theme.spacing.l * 2
                y: Theme.spacing.l
                width: parent.width - Theme.spacing.l * 4
                spacing: Theme.spacing.m

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: Theme.spacing.m
                    icon: root.current.icon
                    color: Colors.m3primary
                    font.pixelSize: Theme.welcome.icon
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.current.title
                    color: Colors.m3onSurface
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.title
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.current.text
                    color: Colors.m3onSurfaceVariant
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.normal
                    lineHeight: 1.3
                    wrapMode: Text.Wrap
                }

                // The step's keys as key caps (the same look as Settings -> Keybinds), several
                // combinations separated by "or".
                Row {
                    visible: root.current.keys.length > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacing.s

                    Repeater {
                        model: root.current.keys

                        Row {
                            id: combo

                            required property var modelData
                            required property int index

                            spacing: Theme.spacing.xs

                            Text {
                                visible: combo.index > 0
                                anchors.verticalCenter: parent.verticalCenter
                                rightPadding: Theme.spacing.xs
                                text: "or"
                                color: Colors.m3onSurfaceVariant
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.small
                            }

                            Repeater {
                                model: combo.modelData

                                Rectangle {
                                    required property string modelData

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(height, cap.implicitWidth + Theme.spacing.m)
                                    height: cap.implicitHeight + Theme.spacing.xs * 2
                                    radius: Theme.radius.s
                                    color: Colors.m3surfaceContainerHighest
                                    border.width: 1
                                    border.color: Colors.m3outlineVariant

                                    Text {
                                        id: cap
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        color: Colors.m3onSurface
                                        font.family: Theme.font.sans
                                        font.pixelSize: Theme.font.small
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }

                // Where in the tour: a dot per card, the current one wide.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: Theme.spacing.s
                    spacing: Theme.spacing.xs

                    Accessible.role: Accessible.StaticText
                    Accessible.name: "Step " + (root.step + 1) + " of " + root.steps.length

                    Repeater {
                        model: root.steps.length

                        Rectangle {
                            required property int index

                            width: index === root.step ? Theme.welcome.dot * 3 : Theme.welcome.dot
                            height: Theme.welcome.dot
                            radius: height / 2
                            color: index === root.step ? Colors.m3primary : Colors.m3outlineVariant

                            Behavior on width {
                                NumberAnimation { duration: Theme.anim.fast }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: next.implicitHeight

                    TextButton {
                        anchors.left: parent.left
                        visible: !root.last
                        text: "Skip"
                        onClicked: root.close()
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: Theme.spacing.s

                        TextButton {
                            visible: root.step > 0
                            text: "Back"
                            onClicked: root.previous()
                        }

                        TextButton {
                            id: next
                            filled: true
                            text: root.last ? "Done" : "Next"
                            onClicked: root.next()
                        }
                    }
                }
            }
        }
    }
}
