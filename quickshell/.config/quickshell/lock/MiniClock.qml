import QtQuick

// The lock screen's clock shrunk to fit a picture card (`box`) in the lock screen editor,
// showing the sample time 10:09. Its style and font are set by the card.
LockClock {
    required property Item box
    property real fill: 0.7 // how much of the card's width (or 60 % of its height) it may take

    date: new Date(2026, 0, 1, 10, 9)
    scale: Math.min(box.width * fill / Math.max(implicitWidth, 1), box.height * 0.6 / Math.max(implicitHeight, 1))
    width: implicitWidth
    height: implicitHeight
}
