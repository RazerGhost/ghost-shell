import QtQuick
import qs.theme

// An outline around a part of the lock screen in the lock screen editor's card (`area`, in the
// lock screen's own units), like an iOS lock screen being edited; its line is scaled back to the
// usual width, and clicking it opens that part's tab (customize/LockEditor.qml). Dragging it
// (or the arrow keys while it has the keyboard) moves that part: `moving` while the pointer
// is down, then `moved` once let go, both in the lock screen's own units.
Rectangle {
    id: outline

    property string tab
    property string name
    property bool shown
    property rect area
    // The editor's frame, whose tab it shows and opens.
    required property EditorChrome sheet

    // How far it's dragged from where the press began, in the lock screen's units.
    signal moving(point by)
    // Let go after `moving`, or an arrow key's step (`by`).
    signal moved(point by)

    visible: shown
    x: area.x - Theme.spacing.m
    y: area.y - Theme.spacing.m
    width: area.width + Theme.spacing.m * 2
    height: area.height + Theme.spacing.m * 2
    radius: Theme.radius.l
    color: hover.hovered || drag.active ? Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, Theme.state.hover)
                                      : "transparent"
    border.width: Theme.outline.normal / sheet.cardScale
    border.color: sheet.tab === tab || activeFocus ? Colors.m3primary
                : Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, 0.5)

    Accessible.role: Accessible.Button
    Accessible.name: name + "; drag or use the arrow keys to move it"
    Accessible.onPressAction: sheet.tab = tab
    activeFocusOnTab: true
    Keys.onSpacePressed: sheet.tab = tab
    Keys.onPressed: event => {
        const step = Theme.spacing.l * 2;
        const by = event.key === Qt.Key_Left ? Qt.point(-step, 0) : event.key === Qt.Key_Right ? Qt.point(step, 0)
                 : event.key === Qt.Key_Up ? Qt.point(0, -step) : event.key === Qt.Key_Down ? Qt.point(0, step) : null;
        if (by) {
            moved(by);
            event.accepted = true;
        }
    }

    HoverHandler {
        id: hover
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: outline.sheet.tab = outline.tab
    }

    // The pointer's move on the screen in the lock screen's units: the card shows it scaled.
    DragHandler {
        id: drag
        target: null
        property point by: Qt.point(0, 0)
        onCentroidChanged: {
            if (!active)
                return;
            by = Qt.point((centroid.scenePosition.x - centroid.scenePressPosition.x) / outline.sheet.cardScale,
                          (centroid.scenePosition.y - centroid.scenePressPosition.y) / outline.sheet.cardScale);
            outline.moving(by);
        }
        onActiveChanged: {
            if (active) {
                by = Qt.point(0, 0);
                return;
            }
            outline.moved(by);
        }
    }
}
