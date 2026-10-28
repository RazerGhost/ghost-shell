import QtQuick
import qs.theme

// Every workspace as a number, shown while hovering the dots (user's choice): the current one
// filled, ones with windows bright, empty ones dim. Click one to go there.
Row {
    id: root

    required property var workspaces // the island's Workspaces: slots, existing, active, go()

    spacing: Theme.spacing.s

    Repeater {
        model: root.workspaces.slots

        Rectangle {
            id: number

            required property int modelData
            readonly property bool isActive: modelData === root.workspaces.active
            readonly property bool occupied: (root.workspaces.existing[modelData]?.toplevels.values.length ?? 0) > 0

            width: Theme.workspace.number
            height: Theme.workspace.number
            radius: Theme.radius.full
            color: isActive ? Colors.m3primary : mouse.containsMouse ? Colors.m3surfaceContainerHighest : "transparent"

            Accessible.role: Accessible.Button
            Accessible.name: "Workspace " + modelData + (isActive ? ", current" : occupied ? "" : ", empty")
            Accessible.onPressAction: root.workspaces.go(modelData)

            Text {
                anchors.centerIn: parent
                text: number.modelData
                color: number.isActive ? Colors.m3onPrimary : Colors.m3onSurface
                opacity: number.isActive || number.occupied ? 1 : 0.4
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                font.weight: number.isActive ? Font.DemiBold : Font.Normal
                font.features: { "tnum": 1 }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.workspaces.go(number.modelData)
            }
        }
    }
}
