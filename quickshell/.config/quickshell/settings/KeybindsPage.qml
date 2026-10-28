import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.widgets
import "Keybinds.js" as Keybinds

// Every keybind with what it does, read from Hyprland (`hyprctl binds -j`), so the list always
// matches hypr/binds.lua: by category (binds.lua describes them as "Category: what it does",
// grouped by Keybinds.js), each key a key cap, with a search over what they do and their keys.
// Re-read each time the page is shown.
Column {
    id: root

    property var groups: []
    readonly property string query: search.text.trim().toLowerCase()
    // The groups with only the rows the search matches (all without a search); empty groups go.
    readonly property var shown: groups.map(g => ({
        category: g.category,
        rows: query === "" ? g.rows : g.rows.filter(r => (g.category + " " + r.description + " "
            + r.combos.map(c => c.join(" ")).join(" ")).toLowerCase().includes(query))
    })).filter(g => g.rows.length > 0)

    spacing: Theme.spacing.l
    onVisibleChanged: {
        if (visible)
            read.running = true;
    }
    Component.onCompleted: read.running = true

    Process {
        id: read
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.groups = Keybinds.groups(JSON.parse(text))
        }
    }

    SearchField {
        id: search
        width: parent.width
        placeholder: "Search keybinds (\"screenshot\", \"Super + E\")"
    }

    Repeater {
        model: root.shown

        SettingGroup {
            id: group

            required property var modelData

            title: modelData.category

            Repeater {
                model: group.modelData.rows

                Item {
                    id: bindRow

                    required property var modelData

                    width: parent.width
                    implicitHeight: Math.max(Theme.list.rowHeight - Theme.spacing.m, keys.implicitHeight + Theme.spacing.s * 2)

                    Accessible.role: Accessible.StaticText
                    Accessible.name: modelData.description + ": " + modelData.combos.map(c => c.join(" + ")).join(" or ")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacing.l
                        anchors.right: keys.left
                        anchors.rightMargin: Theme.spacing.m
                        anchors.verticalCenter: parent.verticalCenter
                        text: bindRow.modelData.description
                        color: Colors.m3onSurface
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.normal
                        elide: Text.ElideRight
                    }

                    // Each combination as key caps; several are separated by "or".
                    Row {
                        id: keys
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacing.l
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacing.s

                        Repeater {
                            model: bindRow.modelData.combos

                            Row {
                                id: comboRow

                                required property var modelData
                                required property int index

                                spacing: Theme.spacing.xs

                                Text {
                                    visible: comboRow.index > 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    rightPadding: Theme.spacing.xs
                                    text: "or"
                                    color: Colors.m3onSurfaceVariant
                                    font.family: Theme.font.sans
                                    font.pixelSize: Theme.font.small
                                }

                                Repeater {
                                    model: comboRow.modelData

                                    Rectangle {
                                        required property string modelData

                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(height, cap.implicitWidth + Theme.spacing.m)
                                        height: cap.implicitHeight + Theme.spacing.xs * 2
                                        radius: Theme.radius.s
                                        color: Colors.m3surfaceContainerHighest
                                        border.width: 1
                                        border.color: Colors.m3outlineVariant

                                        Text {
                                            id: cap
                                            anchors.centerIn: parent
                                            text: parent.modelData
                                            color: Colors.m3onSurface
                                            font.family: Theme.font.sans
                                            font.pixelSize: Theme.font.small
                                            font.weight: Font.Medium
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    TextButton {
        text: "Show the welcome tour"
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "welcome", "show"])
    }

    Text {
        width: parent.width
        leftPadding: Theme.spacing.l
        text: root.shown.length === 0 && root.groups.length > 0 ? "No keybind matches." : "Change them in hypr/binds.lua in the dotfiles."
        color: Colors.m3onSurfaceVariant
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        wrapMode: Text.Wrap
    }
}
