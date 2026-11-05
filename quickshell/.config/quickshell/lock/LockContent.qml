import QtQuick
import QtQuick.Effects
import qs.bar
import qs.desktop
import qs.services
import qs.theme
import "../services/FileUrl.js" as FileUrl
import "LockMotion.js" as LockMotion

// What the lock screen shows on each monitor: your desktop, locked (user's choice, 2026-11-04:
// not a screen of its own). The desktop's wallpaper, its widgets where you placed them (on the
// first screen, like the desktop's; desktop/WidgetStage.qml, locked: only the media widget takes
// clicks, and the calendar and to-do keep their titles to themselves), and the island at the top,
// which opens into the password field (LockIsland.qml). The island and the widgets are glass over
// a blurred copy of the wallpaper, as Hyprland blurs them on the desktop: its blur can't reach
// inside the lock screen's own surface. Lock.qml checks the password.
Item {
    id: root

    // Shown under the password field: "Wrong password", or PAM's own messages.
    property string message
    property bool messageIsError
    // A password is being checked; the field waits.
    property bool busy
    // The password was right: the island closes with the lock open (Lock.qml unlocks after).
    property bool unlocking
    // The desktop's picture (a live wallpaper's still frame); "" shows the plain background color.
    property string wallpaper
    // The desktop widgets: only on the screen the desktop shows them on.
    property bool showsWidgets: true

    signal submitted(string password)
    // A key or a real pointer move: Lock.qml unlocks during the idle lock's grace period.
    signal activity()

    // The lock screens on other monitors clear theirs too after a try; a wrong password also
    // shakes the island.
    function clear(failed: bool): void {
        island.clear(failed);
    }

    Component.onCompleted: island.field.forceActiveFocus()

    // Fades in from black when it appears (Hyprland shows nothing behind a lock screen).
    opacity: 0
    NumberAnimation on opacity {
        to: 1
        duration: Theme.anim.morph
        easing.type: Theme.anim.easing
    }

    // Where the pointer first showed up: a move away from it counts as activity, so the
    // pointer merely being there when the lock screen appears doesn't.
    property point pointerStart: Qt.point(-1, -1)

    HoverHandler {
        onPointChanged: {
            const p = point.position;
            if (root.pointerStart.x < 0) {
                root.pointerStart = p;
            } else if (LockMotion.moved(root.pointerStart, p, Theme.lock.moved)) {
                root.activity();
                island.wake();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.m3surface
    }

    Image {
        id: picture
        anchors.fill: parent
        // Only once it has its size: decoded at 0 x 0 it was read at full size first, then again.
        source: width > 0 ? FileUrl.of(root.wallpaper) : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        // A live wallpaper's still frame is always video-frame.jpg: a cached copy could be an
        // older video's.
        cache: false
    }

    // The glass: the wallpaper blurred, only behind the island and the widgets' cards.
    MultiEffect {
        anchors.fill: parent
        visible: picture.status === Image.Ready
        source: picture
        blurEnabled: true
        blur: 1
        blurMax: Theme.lock.blur
        // No padding around the blur: padded, the mask was stretched over a larger area than the
        // picture, and the glass sat off its cards.
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: glass
        maskSpreadAtMin: 1 // smooth edges (by default any trace of a shape counts as inside)
    }

    Item {
        id: glass
        anchors.fill: parent
        visible: false
        layer.enabled: true

        PillShape {
            x: island.pill.x + island.pill.outline.x + island.shake
            y: island.pill.y + island.pill.outline.y
            attached: Theme.island.attached
            bodyWidth: island.pill.outline.bodyWidth
            bodyHeight: island.pill.outline.bodyHeight
            radius: island.pill.outline.radius
            color: "white"
        }

        Repeater {
            model: root.showsWidgets ? widgets.cards : []

            Rectangle {
                required property Item modelData
                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height
                visible: modelData.visible
                opacity: modelData.opacity
                scale: modelData.scale // a card lifts a little under the pointer
                radius: Theme.desktop.radius
                color: "white"
            }
        }
    }

    WidgetStage {
        id: widgets
        anchors.fill: parent
        visible: root.showsWidgets
        locked: true
    }

    LockIsland {
        id: island
        anchors.fill: parent
        message: root.message
        messageIsError: root.messageIsError
        busy: root.busy
        unlocking: root.unlocking
        onSubmitted: password => root.submitted(password)
        onTyped: root.activity()
    }

    // Your own line at the bottom (Settings -> Lock screen -> Message): "If found, call ...".
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.l * 2
        width: Math.min(implicitWidth, parent.width * 0.5)
        visible: text !== ""
        text: Settings.values.lockMessage
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.large
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        style: Text.Raised
        styleColor: Colors.scrim
    }
}
