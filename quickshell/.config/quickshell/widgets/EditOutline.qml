import QtQuick
import qs.theme

// An outline around a part of the lock screen in the lock screen editor's card (`area`, in its
// parent's units: the part itself), like an iOS lock screen being edited; its line is scaled
// back to the usual width, and clicking it (or Enter) opens that part's tab, if it has one
// (customize/LockEditor.qml). Shown only while `sheet` (the editor's frame) is set.
// Dragging it moves that part: `moving` while the pointer is down, then `moved` once let go, both
// in the lock screen's own units; Shift + an arrow key steps it (`stepped`). The plain arrow
// keys move on to the next control and Escape cancels, as everywhere in the editor: the card
// isn't inside the editor's frame, so they're handed to it here.
Rectangle {
    id: outline

    property string tab
    property string name
    property bool shown
    property rect area
    // The editor's frame (customize/EditorChrome.qml), whose tab it shows and opens; null
    // outside the editor.
    property var sheet: null

    // How far it's dragged from where the press began, in the lock screen's units.
    signal moving(point by)
    // Let go after `moving`.
    signal moved(point by)
    // An arrow key's step (`by`): glided to, not dragged.
    signal stepped(point by)

    visible: shown && sheet !== null
    x: area.x - Theme.spacing.m
    y: area.y - Theme.spacing.m
    width: area.width + Theme.spacing.m * 2
    height: area.height + Theme.spacing.m * 2
    radius: Theme.radius.l
    color: hover.hovered || drag.active ? Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, Theme.state.hover)
                                      : "transparent"
    border.width: Theme.outline.normal / (sheet?.cardScale ?? 1)
    border.color: (tab !== "" && sheet?.tab === tab) || activeFocus ? Colors.m3primary
                : Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, 0.5)

    Accessible.role: Accessible.Button
    Accessible.name: name
    Accessible.description: "Drag it, or Shift and the arrow keys, to move it"
    Accessible.onPressAction: openTab()
    activeFocusOnTab: true
    Keys.onSpacePressed: openTab()
    Keys.onReturnPressed: openTab()
    Keys.onEnterPressed: openTab()

    function openTab(): void {
        if (tab !== "")
            sheet.tab = tab;
    }
    Keys.onEscapePressed: sheet.cancelled()
    Keys.onPressed: event => {
        const arrows = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down];
        if (!arrows.includes(event.key))
            return;
        if (!(event.modifiers & Qt.ShiftModifier)) {
            event.accepted = sheet.navigate(event.key);
            return;
        }
        const step = Theme.spacing.l * 2;
        stepped(event.key === Qt.Key_Left ? Qt.point(-step, 0) : event.key === Qt.Key_Right ? Qt.point(step, 0)
              : event.key === Qt.Key_Up ? Qt.point(0, -step) : Qt.point(0, step));
        event.accepted = true;
    }

    HoverHandler {
        id: hover
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: outline.openTab()
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
