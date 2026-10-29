import QtQuick
import qs.theme
import qs.widgets

// A card of related settings, with an optional heading above it.
Column {
    id: root

    property string title
    default property alias rows: card.data

    width: parent?.width ?? 0
    spacing: Theme.spacing.s

    SectionHeading {
        visible: root.title !== ""
        leftPadding: Theme.spacing.l
        text: root.title
    }

    Rectangle {
        width: parent.width
        height: card.implicitHeight + Theme.spacing.xs * 2
        radius: Theme.radius.l
        color: Colors.m3surfaceContainer

        Column {
            id: card
            y: Theme.spacing.xs
            width: parent.width
        }
    }
}
