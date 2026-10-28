import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.theme
import "../services/SnapLayout.js" as SnapLayout

// The snap layouts, like Windows 11's: small pictures of the screen with the target area lit,
// in two rows of groups. Click one to put `target` there.
Column {
    id: root

    property HyprlandToplevel target

    // A layout was picked; the picker closes.
    signal done()

    spacing: Theme.spacing.s

    // One layout: a little screen with the window's area in the accent color.
    component LayoutButton: MouseArea {
        id: button

        required property string layout
        readonly property var cell: SnapLayout.layout(layout)

        function pick(): void {
            Snap.snap(root.target, layout);
            root.done();
        }

        width: Theme.snap.width
        height: width * 9 / 16
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.target !== null
        onClicked: pick()

        Accessible.role: Accessible.Button
        Accessible.name: "Snap to " + layout.replace(/-/g, " ")
        Accessible.onPressAction: pick()

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.s
            color: Colors.m3surfaceContainerHighest
        }

        Rectangle {
            readonly property real pad: 3
            readonly property real cellW: (parent.width - pad * 2) / button.cell.cols
            readonly property real cellH: (parent.height - pad * 2) / button.cell.rows

            x: pad + button.cell.col * cellW
            y: pad + button.cell.row * cellH
            width: cellW * (button.cell.span || 1) - 2
            height: cellH * (button.cell.rowSpan || 1) - 2
            radius: Theme.radius.s - 2
            color: Colors.m3primary
            opacity: button.containsMouse ? 1 : 0.55

            Behavior on opacity {
                NumberAnimation { duration: Theme.anim.fast }
            }
        }
    }

    component Group: Column {
        property alias title: label.text
        default property alias buttons: row.data

        spacing: Theme.spacing.xs

        Text {
            id: label
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.small
        }

        Row {
            id: row
            spacing: Theme.spacing.xs
        }
    }

    Row {
        spacing: Theme.spacing.l

        Group {
            title: "Halves"
            LayoutButton { layout: "left" }
            LayoutButton { layout: "right" }
        }

        Group {
            title: "Thirds"
            LayoutButton { layout: "left-third" }
            LayoutButton { layout: "center-third" }
            LayoutButton { layout: "right-third" }
        }
    }

    Row {
        spacing: Theme.spacing.l

        Group {
            title: "Quarters"
            LayoutButton { layout: "top-left" }
            LayoutButton { layout: "top-right" }
            LayoutButton { layout: "bottom-left" }
            LayoutButton { layout: "bottom-right" }
        }

        Group {
            title: "Two thirds"
            LayoutButton { layout: "left-two-thirds" }
            LayoutButton { layout: "right-two-thirds" }
        }
    }
}
