import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.widgets

// What every on-screen editor has around what it edits: Cancel and Done in the top corners
// (Escape and Enter too), and a sheet at the bottom with tabs. The tabs' contents go inside;
// each shows itself for its `tab`. Fills the editor's window.
//
// The sheet is a panel like the shell's own, so the glass settings show on it while they're
// changed: with `glass` Hyprland blurs behind it (the editor's window must ask for that, see
// DesktopEditor.qml); with a `backdrop` (what's behind it in the same window, the lock screen)
// it blurs that itself, frosted. Without either it's nearly solid.
Item {
    id: root

    // [{ value, label }]
    required property var tabs
    property string tab: tabs[0]?.value ?? ""
    property bool glass: false
    property Item backdrop: null
    // In the middle of the screen instead of at the bottom (the dock and island editor: the
    // dock is at the bottom).
    property bool centered: false
    // A short note under the tabs while something takes a moment ("Making the colors…").
    property string status
    default property alias content: sheetColumn.data
    readonly property Item sheet: sheet
    // Cancel's and Done's pills, for an editor's input mask (the desktop editor's).
    property Item cancelPill: null
    property Item donePill: null

    signal cancelled()
    signal finished()

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
            // Glass only with Hyprland's blur behind; over the lock screen they stay solid.
            color: root.glass ? Colors.surfaceTranslucent : root.solid

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

    Item {
        id: sheet

        readonly property real radius: Theme.radius.l * 1.5

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.centered ? (parent.height - height) / 2 : parent.height - height - Theme.spacing.l * 2
        width: Math.min(parent.width - Theme.spacing.l * 4, Theme.editor.sheet)
        height: tabsColumn.height + Theme.spacing.l
        Behavior on height { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing } }

        // Frosted: what's behind the sheet in this window, blurred like Hyprland's blur.
        ClippingRectangle {
            anchors.fill: parent
            visible: root.backdrop !== null
            radius: sheet.radius
            color: "transparent"

            MultiEffect {
                anchors.fill: parent
                source: ShaderEffectSource {
                    sourceItem: root.backdrop
                    sourceRect: Qt.rect(sheet.x, sheet.y, sheet.width, sheet.height)
                    live: true
                }
                blurEnabled: true
                blur: 1
                blurMax: Theme.lock.blur
            }
        }

        Surface {
            anchors.fill: parent
            radius: sheet.radius
            color: root.glass || root.backdrop ? Colors.surfaceTranslucent : root.solid
        }

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

            Text {
                width: parent.width
                height: root.status !== "" ? implicitHeight + Theme.spacing.s : 0
                topPadding: Theme.spacing.s
                visible: root.status !== ""
                horizontalAlignment: Text.AlignHCenter
                text: root.status
                color: Colors.m3onSurfaceVariant
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.small
            }

            Column {
                id: sheetColumn
                width: parent.width
            }
        }
    }
}
