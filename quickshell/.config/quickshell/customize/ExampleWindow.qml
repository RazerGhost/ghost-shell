import QtQuick
import Quickshell
import qs.theme

// A stand-in app window for the windows editor (WindowsEditor.qml): a title and a few lines of
// placeholder text in your colors, so borders, corners, gaps and animations show on something
// that looks like a real window. Hyprland tiles or floats it by its title (rules.lua), and
// positions.lua leaves it out (it shares Quickshell's class with the Settings window).
FloatingWindow {
    id: root

    required property string heading

    title: heading
    implicitWidth: Theme.editor.sample
    implicitHeight: Math.round(Theme.editor.sample * 0.6)
    color: Colors.m3surface

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacing.l * 1.5
        spacing: Theme.spacing.m

        Text {
            text: root.heading
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.title
            font.weight: Font.DemiBold
        }

        // Lines of "text", shorter towards the end like a paragraph.
        Repeater {
            model: [0.9, 0.75, 0.85, 0.5]

            Rectangle {
                required property real modelData
                width: parent.width * modelData
                height: Theme.spacing.s
                radius: height / 2
                color: Colors.m3surfaceContainerHighest
            }
        }

        Rectangle {
            width: Theme.editor.sample * 0.3
            height: Theme.island.height
            radius: Theme.radius.full
            color: Colors.m3primary
        }
    }
}
