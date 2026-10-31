import QtQuick
import qs.theme
import qs.widgets

// One tile or round button in quick settings (QuickSettings.qml), in its place in your order.
// In edit mode, like Android's: it wiggles a little, a badge in its corner removes it, and
// dragging it onto another one moves it there (or Shift + Left / Right with the keyboard,
// Delete removes). A wide tile also has a badge in the other corner that makes it large or
// small (Enter or Space). Out of edit mode it's just the control.
Item {
    id: slot

    required property string itemId
    required property int index
    required property string title
    property Component control
    property bool editing: false
    // The control's corners, for the keyboard's ring (the round buttons are circles).
    property real radius: Theme.radius.l
    // Wide tiles: large (the whole row) or small (half), switched in edit mode.
    property bool resizable: false
    property bool large: false

    signal removeRequested()
    signal resizeRequested()
    // Dropped onto the slot at `to` (or moved there with the keyboard).
    signal moveRequested(int to)

    width: body.width
    height: body.height
    // Over the others while dragged.
    z: dragArea.drag.active ? 10 : 0

    Item {
        id: body
        width: loader.width
        height: loader.height

        // A slow wiggle while editing, not while dragged.
        property real wiggle: 0
        rotation: slot.editing && !dragArea.drag.active ? wiggle : 0
        SequentialAnimation on wiggle {
            running: slot.editing && Theme.anim.speed > 0
            loops: Animation.Infinite
            NumberAnimation { to: 1.2; duration: Theme.anim.morph; easing.type: Easing.InOutSine }
            NumberAnimation { to: -1.2; duration: Theme.anim.morph; easing.type: Easing.InOutSine }
        }

        Loader {
            id: loader
            sourceComponent: slot.control
            // The control's own clicks wait while editing.
            enabled: !slot.editing
        }
    }

    // Edit mode: drag the slot onto another to move it there.
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: slot.editing
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: body
        onReleased: mouse => {
            const at = mapToItem(slot.parent, mouse.x, mouse.y);
            const target = slot.parent.childAt(at.x, at.y);
            body.x = 0;
            body.y = 0;
            if (target && target !== slot && target.index !== undefined)
                slot.moveRequested(target.index);
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: !slot.editing ? slot.title
        : slot.title + ": Shift and arrow keys move it, Delete removes it"
          + (slot.resizable ? ", Enter makes it " + (slot.large ? "small" : "large") : "")
    activeFocusOnTab: slot.editing
    Keys.onPressed: event => {
        if (!slot.editing)
            return;
        if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            slot.removeRequested();
            event.accepted = true;
        } else if (slot.resizable && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
            slot.resizeRequested();
            event.accepted = true;
        } else if (event.modifiers & Qt.ShiftModifier && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
            slot.moveRequested(slot.index + (event.key === Qt.Key_Left ? -1 : 1));
            event.accepted = true;
        }
    }

    FocusRing {
        radius: slot.radius
    }

    // The badge that removes it.
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: -Theme.spacing.xs
        width: Theme.icon.small + Theme.spacing.xs
        height: width
        radius: width / 2
        visible: slot.editing
        color: Colors.m3surfaceContainerHighest
        border.width: Theme.outline.normal
        border.color: Colors.m3outlineVariant

        MaterialIcon {
            anchors.centerIn: parent
            icon: "remove"
            color: Colors.m3onSurface
            font.pixelSize: Theme.icon.small
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Theme.spacing.xs
            cursorShape: Qt.PointingHandCursor
            onClicked: slot.removeRequested()
        }

        Accessible.role: Accessible.Button
        Accessible.name: "Remove " + slot.title
        Accessible.onPressAction: slot.removeRequested()
    }

    // The badge that makes a wide tile large or small.
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: -Theme.spacing.xs
        width: Theme.icon.small + Theme.spacing.xs
        height: width
        radius: width / 2
        visible: slot.editing && slot.resizable
        color: Colors.m3surfaceContainerHighest
        border.width: Theme.outline.normal
        border.color: Colors.m3outlineVariant

        MaterialIcon {
            anchors.centerIn: parent
            icon: slot.large ? "close_fullscreen" : "open_in_full"
            color: Colors.m3onSurface
            font.pixelSize: Theme.icon.small
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -Theme.spacing.xs
            cursorShape: Qt.PointingHandCursor
            onClicked: slot.resizeRequested()
        }

        Accessible.role: Accessible.Button
        Accessible.name: (slot.large ? "Make small: " : "Make large: ") + slot.title
        Accessible.onPressAction: slot.resizeRequested()
    }
}
