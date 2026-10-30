import QtQuick
import qs.widgets

// A part of the lock screen outlined in the lock screen editor (widgets/EditOutline.qml), as a
// child of the part itself, so it moves with it: dragging it, or Shift + arrows, moves the part
// (LockContent.dragPart, movePart). Nothing outside the editor (`content.editor` is null).
EditOutline {
    required property Item content
    // The part's name in lockPlaces, and the item it outlines and moves.
    required property string part
    required property Item target

    sheet: content.editor
    shown: true
    area: Qt.rect(0, 0, target.width, target.height)

    onMoving: by => content.dragPart(part, by)
    onMoved: by => content.movePart(part, target, by, true)
    onStepped: by => content.movePart(part, target, by, false)
}
