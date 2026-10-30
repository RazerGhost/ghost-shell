import QtQuick
import qs.theme

// A row of key hints at the foot of something made for the keyboard (the editors' sheet, the
// customize menu): each its keys as key caps and what they do. `hints`: [{ keys, label }].
Row {
    id: root

    required property var hints

    spacing: Theme.spacing.l
    opacity: 0.8

    Repeater {
        model: root.hints

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
