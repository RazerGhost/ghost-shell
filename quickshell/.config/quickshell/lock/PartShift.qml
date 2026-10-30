import QtQuick
import qs.theme

// Moves a part of the lock screen (the clock, the date, the player, a widget) to where it was
// dragged (LockContent.shiftOf: its saved place, or the drag going on, kept clear of the field).
// Glides to a new place; follows a drag at once.
Translate {
    // The LockContent it's in, the part's name in lockPlaces, and the item it moves.
    required property Item content
    required property string name
    required property Item target

    readonly property var shift: content.shiftOf(name, target)

    x: shift.x
    y: shift.y
    Behavior on x { enabled: !content.dragging && !content.settling; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
    Behavior on y { enabled: !content.dragging && !content.settling; NumberAnimation { duration: Theme.anim.morph; easing.type: Theme.anim.easing } }
}
