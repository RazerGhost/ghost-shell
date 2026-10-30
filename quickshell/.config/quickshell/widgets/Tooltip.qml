import QtQuick
import qs.theme

// A small label for `target` while the pointer rests on it (`shown`): what an icon-only button
// does. It's moved to the top of the window, so a menu's or list's clip can't cut it off, under
// the target, or above it when there's no room below.
Rectangle {
    id: root

    required property Item target
    property string text
    property bool shown

    // Shown after a short rest, gone at once.
    property bool resting: false

    function place(): void {
        if (!parent || !target)
            return;
        const at = target.mapToItem(parent, 0, 0);
        x = Math.max(Theme.tooltip.gap, Math.min(parent.width - width - Theme.tooltip.gap, at.x + (target.width - width) / 2));
        const below = at.y + target.height + Theme.tooltip.gap;
        y = below + height <= parent.height ? below : at.y - height - Theme.tooltip.gap;
    }

    // Until its window exists (a hidden window's items, a Repeater's new delegate) there's no
    // content item: null, not undefined, which QML refuses for an Item (a warning per tooltip).
    parent: (target && target.Window.contentItem) || null
    z: 1000
    width: label.implicitWidth + Theme.spacing.m * 2
    height: label.implicitHeight + Theme.spacing.xs * 2
    radius: Theme.radius.full
    color: Colors.m3surfaceContainerHighest
    opacity: resting && text !== "" ? 1 : 0
    visible: opacity > 0

    onShownChanged: {
        if (shown) {
            wait.restart();
        } else {
            wait.stop();
            resting = false;
        }
    }
    onRestingChanged: {
        if (resting)
            place();
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.anim.fast }
    }

    Timer {
        id: wait
        interval: Theme.tooltip.delay
        onTriggered: root.resting = true
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Colors.m3onSurface
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
    }
}
