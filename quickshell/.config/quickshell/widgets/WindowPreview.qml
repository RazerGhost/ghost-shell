import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.theme

// A window as a live preview with its app icon and title under it: Alt+Tab, the overview and
// Snap Assist. The preview keeps the window's shape inside the frame. Clicking and dragging are
// up to the user of this; `closable` adds an × (on hover) that closes the window.
Item {
    id: root

    required property HyprlandToplevel toplevel
    // Accent outline: the selected or hovered window.
    property bool highlighted
    // Capture only while the preview is on screen.
    property bool capturing: true
    property bool closable
    // The frame's height; the title row takes the rest (Theme.switcher.labelHeight).
    property real previewHeight: height - Theme.switcher.labelHeight
    readonly property alias hovered: hover.hovered

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: frame

        width: parent.width
        height: root.previewHeight
        radius: Theme.radius.m
        color: Colors.m3surfaceContainerHigh
        border.width: root.highlighted ? Theme.outline.strong : 0
        border.color: Colors.m3primary

        ScreencopyView {
            anchors.centerIn: parent
            captureSource: root.capturing ? root.toplevel?.wayland ?? null : null
            live: true
            // Fit inside the frame (inside its outline), keeping the window's shape.
            constraintSize: Qt.size(frame.width - 6, frame.height - 6)
        }

        IconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Theme.spacing.s
            visible: root.closable && hover.hovered
            icon: "close"
            label: "Close " + (root.toplevel?.title ?? "window")
            color: Colors.m3onSurface
            onClicked: Windows.close(root.toplevel)

            Rectangle {
                anchors.fill: parent
                z: -1
                radius: Theme.radius.full
                color: Colors.surfaceTranslucent
            }
        }
    }

    Row {
        anchors.top: frame.bottom
        anchors.topMargin: Theme.spacing.s
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(implicitWidth, parent.width)
        spacing: Theme.spacing.s

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: Theme.icon.normal
            source: Quickshell.iconPath(Windows.iconFor(root.toplevel), "application-x-executable")
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.width - Theme.icon.normal - parent.spacing)
            text: root.toplevel?.title ?? ""
            color: Colors.m3onSurface
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            font.weight: root.highlighted ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
        }
    }
}
