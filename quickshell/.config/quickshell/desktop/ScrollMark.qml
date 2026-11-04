import QtQuick
import qs.theme

// A thin bar at the right edge of a widget's list that scrolls (the note, the to-do and
// clipboard widgets): how much of it shows and where. Only while there's more than fits.
// Place it beside the Flickable, in the same parent.
Rectangle {
    required property Flickable flickable

    visible: flickable.visible && flickable.contentHeight > flickable.height + 1
    x: flickable.x + flickable.width - width
    y: flickable.y + flickable.visibleArea.yPosition * flickable.height
    width: Theme.desktop.scrollMark
    height: flickable.visibleArea.heightRatio * flickable.height
    radius: width / 2
    color: Colors.m3onSurfaceVariant
    opacity: 0.5
}
