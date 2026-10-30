import QtQuick
import qs.theme

// An outline around a part of the lock screen in the lock screen editor's card (`area`, in the
// lock screen's own units), like an iOS lock screen being edited; its line is scaled back to the
// usual width, and clicking it opens that part's tab (customize/LockEditor.qml).
Rectangle {
    id: outline

    property string tab
    property string name
    property bool shown
    property rect area
    // The editor's frame, whose tab it shows and opens.
    required property EditorChrome sheet

    visible: shown
    x: area.x - Theme.spacing.m
    y: area.y - Theme.spacing.m
    width: area.width + Theme.spacing.m * 2
    height: area.height + Theme.spacing.m * 2
    radius: Theme.radius.l
    color: outlineMouse.containsMouse ? Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, Theme.state.hover)
                                      : "transparent"
    border.width: Theme.outline.normal / sheet.cardScale
    border.color: sheet.tab === tab || activeFocus ? Colors.m3primary
                : Qt.rgba(Colors.m3onSurface.r, Colors.m3onSurface.g, Colors.m3onSurface.b, 0.5)

    Accessible.role: Accessible.Button
    Accessible.name: name
    Accessible.onPressAction: sheet.tab = tab
    activeFocusOnTab: true
    Keys.onSpacePressed: sheet.tab = tab

    MouseArea {
        id: outlineMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sheet.tab = outline.tab
    }
}
