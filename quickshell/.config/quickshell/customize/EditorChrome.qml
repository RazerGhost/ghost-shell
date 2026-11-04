import QtQuick
import qs.services
import qs.theme
import qs.widgets

// What every on-screen editor has around what it edits: a wide sheet at the bottom with Cancel,
// the tabs and Done along its top. The tabs' contents go inside, each a row of tiles
// (SheetTiles) showing itself for its `tab`. Fills the editor's window, and works out the card
// the edited screen is shown as.
//
// Made for the keyboard as much as the pointer (user's request), with the keys shown at the
// sheet's foot: the arrow keys move to the nearest control that way (ArrowNavigation, also
// onto what the card shows), Enter or Space use it, Ctrl+Tab
// and Ctrl+Shift+Tab switch tabs, Ctrl+Enter is Done and Escape Cancel from anywhere; Enter
// with no control chosen is Done too.
//
// The sheet is a panel like the shell's own: Hyprland blurs behind it (the editor's window must
// ask for that, see DesktopEditor.qml), so the glass settings show on it while they're changed.
Item {
    id: root

    // [{ value, label }]
    required property var tabs
    property string tab: tabs[0]?.value ?? ""
    // In the middle of the screen instead of at the bottom (the dock and island editor: the
    // dock is at the bottom).
    property bool centered: false
    // A short note under the tabs while something takes a moment ("Making the colors…").
    property string status
    // Keys of its own for the hints at the sheet's foot: [{ keys, label }].
    property var extraHints: []
    default property alias content: sheetColumn.data
    readonly property Item sheet: sheet

    signal cancelled()
    signal finished()

    // The card the edited screen is shown as (GNOME's workspaces, Android's widget editing):
    // between `cardTop` and the sheet, at the screen's shape, following the sheet's height as
    // tabs change. The desktop and windows editors publish it for the wallpaper and widgets
    // (Editing.card).
    property real cardTop: Theme.spacing.l * 2
    readonly property real cardScale: Math.min((width - Theme.spacing.l * 4) / Math.max(width, 1),
                                               Math.max(sheet.y - Theme.spacing.l * 1.5 - cardTop, 1) / Math.max(height, 1))
    readonly property rect card: Qt.rect((width - width * cardScale) / 2,
                                         cardTop + (sheet.y - Theme.spacing.l * 1.5 - cardTop - height * cardScale) / 2,
                                         width * cardScale, height * cardScale)

    anchors.fill: parent
    focus: true
    // Takes the keyboard itself for Escape and Enter, so a control in what an editor shows can't
    // claim it first.
    Component.onCompleted: forceActiveFocus()

    Keys.onEscapePressed: root.cancelled()
    Keys.onReturnPressed: root.finished()
    Keys.onEnterPressed: root.finished()
    // Arrow keys a control didn't use (a slider keeps Left and Right).
    Keys.onPressed: event => {
        const keys = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down];
        if (keys.includes(event.key) && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
            event.accepted = navigation.move(event.key);
    }

    ArrowNavigation {
        id: navigation
        area: root.parent ?? root
    }

    function switchTab(by: int): void {
        const i = root.tabs.findIndex(t => t.value === root.tab);
        root.tab = root.tabs[(i + by + root.tabs.length) % root.tabs.length].value;
    }

    // Before any control sees them: a focused switch or card would take Enter for itself.
    Shortcut {
        sequences: ["Ctrl+Tab", "Ctrl+PgDown"]
        onActivated: root.switchTab(1)
    }
    Shortcut {
        sequences: ["Ctrl+Shift+Tab", "Ctrl+Backtab", "Ctrl+PgUp"]
        onActivated: root.switchTab(-1)
    }
    Shortcut {
        sequences: ["Ctrl+Return", "Ctrl+Enter"]
        onActivated: root.finished()
    }

    Item {
        id: sheet

        readonly property real radius: Theme.radius.l * 1.5

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.centered ? (parent.height - height) / 2 : parent.height - height - Theme.spacing.l * 2
        width: parent.width - Theme.spacing.l * 4
        height: tabsColumn.height + Theme.spacing.l
        Behavior on height { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.easing } }

        Surface {
            anchors.fill: parent
            radius: sheet.radius
            color: Colors.surfaceTranslucent
        }

        Column {
            id: tabsColumn
            width: parent.width
            topPadding: Theme.spacing.l

            // Cancel, the tabs, Done.
            Item {
                x: Theme.spacing.l
                width: parent.width - Theme.spacing.l * 2
                height: tabSwitch.height

                TextButton {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Cancel"
                    onClicked: root.cancelled()
                }

                Segmented {
                    id: tabSwitch
                    tabs: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: root.tabs.length > 1 ? 1 : 0
                    options: root.tabs
                    current: root.tab
                    onPicked: v => root.tab = v
                }

                TextButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Done"
                    filled: true
                    onClicked: root.finished()
                }
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

            // The keys, at the sheet's foot (and the editor's own, `extraHints`).
            KeyHints {
                anchors.horizontalCenter: parent.horizontalCenter
                bottomPadding: Theme.spacing.xs
                hints: [
                    { keys: ["←", "↑", "↓", "→"], label: "Move" },
                    { keys: ["Enter"], label: "Choose" }
                ].concat(root.extraHints).concat([
                    { keys: ["Ctrl", "Tab"], label: "Next tab" },
                    { keys: ["Ctrl", "Enter"], label: "Done" },
                    { keys: ["Esc"], label: "Cancel" }
                ].filter(h => h.label !== "Next tab" || root.tabs.length > 1))
            }
        }
    }
}
