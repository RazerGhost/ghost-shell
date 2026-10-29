import QtQuick
import qs.services
import qs.theme
import qs.widgets

// What every on-screen editor has around what it edits: Cancel and Done in the top corners
// (Escape and Enter too), and a sheet at the bottom with tabs. The tabs' contents go inside;
// each shows itself for its `tab`. Fills the editor's window.
Item {
    id: root

    // [{ value, label }]
    required property var tabs
    property string tab: tabs[0]?.value ?? ""
    default property alias content: sheetColumn.data
    readonly property Item sheet: sheet
    // Cancel's and Done's pills, for an editor's input mask (the desktop editor's).
    property Item cancelPill: null
    property Item donePill: null

    signal cancelled()
    signal finished()

    // The editor's own surfaces are nearly solid: what they're over is usually in the same
    // window (the lock screen) or changing (the wallpaper), and blur can't reach under them.
    readonly property color solid: Qt.rgba(Colors.m3surfaceContainer.r, Colors.m3surfaceContainer.g,
                                           Colors.m3surfaceContainer.b, 0.94)

    anchors.fill: parent
    focus: true

    Keys.onEscapePressed: root.cancelled()
    Keys.onReturnPressed: root.finished()
    Keys.onEnterPressed: root.finished()

    Repeater {
        model: [{ text: "Cancel", left: true }, { text: "Done", left: false }]

        Surface {
            id: pill
            required property var modelData
            anchors.top: parent.top
            anchors.left: modelData.left ? parent.left : undefined
            anchors.right: modelData.left ? undefined : parent.right
            anchors.margins: Theme.spacing.l * 2
            width: button.width + Theme.spacing.xs * 2
            height: button.height + Theme.spacing.xs * 2
            radius: Theme.radius.full
            color: root.solid

            Component.onCompleted: {
                if (modelData.left)
                    root.cancelPill = this;
                else
                    root.donePill = this;
            }

            TextButton {
                id: button
                anchors.centerIn: parent
                text: pill.modelData.text
                filled: !pill.modelData.left
                onClicked: pill.modelData.left ? root.cancelled() : root.finished()
            }
        }
    }

    Surface {
        id: sheet
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.l * 2
        width: Math.min(parent.width - Theme.spacing.l * 4, Theme.editor.sheet)
        height: tabsColumn.height + Theme.spacing.l
        radius: Theme.radius.l * 1.5
        color: root.solid
        Behavior on height { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing } }

        Column {
            id: tabsColumn
            width: parent.width
            topPadding: Theme.spacing.l

            Segmented {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.tabs.length > 1
                options: root.tabs
                current: root.tab
                onPicked: v => root.tab = v
            }

            Column {
                id: sheetColumn
                width: parent.width
            }
        }
    }
}
