import QtQuick
import qs.services
import qs.theme
import qs.widgets
import "DesktopWidgets.js" as DesktopWidgets

// One desktop widget at its saved place (Settings' desktopWidgets, as fractions of the screen).
// Resting the pointer on it shows a handle in its top-right corner; drag that to move it. Only
// the handle: the media card's buttons keep their clicks.
Item {
    id: root

    // Its key in desktopWidgets ("clock", "weather", "media").
    required property string name
    default property alias content: body.data

    readonly property var spot: DesktopWidgets.place(Settings.values.desktopWidgets, name)

    // Follows the drag while it lasts; the place is saved on release.
    x: spot.x * parent.width + (drag.active ? drag.translation.x : 0)
    y: spot.y * parent.height + (drag.active ? drag.translation.y : 0)
    width: body.childrenRect.width
    height: body.childrenRect.height

    Item {
        id: body
        anchors.fill: parent
    }

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: handle
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spacing.xs
        width: Theme.icon.normal + Theme.spacing.s
        height: width
        radius: width / 2
        color: Colors.m3surfaceContainerHighest
        opacity: hover.hovered || drag.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

        Accessible.role: Accessible.Button
        Accessible.name: "Move the " + root.name + " widget"

        MaterialIcon {
            anchors.centerIn: parent
            icon: "drag_pan"
            color: Colors.m3onSurfaceVariant
            font.pixelSize: Theme.icon.small
        }

        HoverHandler {
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }

        DragHandler {
            id: drag
            target: null
            onActiveChanged: {
                if (active)
                    return;
                // From the saved place plus the drag: x itself no longer follows it here.
                const area = root.parent;
                const place = DesktopWidgets.dropped(root.spot.x * area.width + translation.x,
                                                     root.spot.y * area.height + translation.y,
                                                     root.width, root.height, area.width, area.height);
                // A new object, so the setting's change is seen and saved.
                Settings.values.desktopWidgets = Object.assign({}, Settings.values.desktopWidgets, { [root.name]: place });
            }
        }
    }
}
