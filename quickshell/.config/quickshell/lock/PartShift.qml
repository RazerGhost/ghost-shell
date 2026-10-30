import QtQuick

// Moves a part of the lock screen (the clock, the date, the player, a widget) to where it was
// dragged (LockContent.shiftOf: its saved place, or the drag going on, kept clear of the field),
// gliding there (GlideTranslate).
GlideTranslate {
    // The part's name in lockPlaces, and the item it moves.
    required property string name
    required property Item target

    readonly property var shift: content.shiftOf(name, target)

    x: shift.x
    y: shift.y
}
