import QtQuick
import Quickshell.Io
import qs.services
import qs.theme
import qs.widgets
import "../services/ClipboardEntries.js" as ClipboardEntries

// The clipboard widget (medium): your pinned texts, then what you copied last
// (services/Clipboard.qml, the clipboard menu's history), a list that scrolls with the wheel or
// touchpad. A click copies one
// again, ready to paste; it says "Copied" for a moment. It follows the clipboard while shown
// (`wl-paste --watch`). On the lock screen (`hidesTitles`) it keeps the clips to itself.
WidgetSurface {
    id: widget

    medium: true
    property bool hidesTitles: false

    readonly property var clips: ClipboardEntries.withPins(Clipboard.pins, Clipboard.entries)
    // What was just copied, for "Copied": by its content, since cliphist stores a copy again
    // under a new id (and moves it to the top) a moment later.
    property string copied: ""
    function key(clip: var): string {
        return clip.image ? "image " + clip.image.size + " " + clip.image.width + "x" + clip.image.height : clip.text;
    }

    // Each change of the clipboard: list it again, a moment later, once cliphist (which watches
    // the same way, hypr/autostart.lua) has stored it. Only while it's seen: every widget is
    // built whether it's on or not (DesktopCard fades it), and on the lock screen it shows none.
    Process {
        running: !widget.hidesTitles && widget.visible
        command: ["wl-paste", "--watch", "echo"]
        stdout: SplitParser {
            onRead: relist.restart()
        }
        onRunningChanged: {
            if (running)
                Clipboard.refresh();
        }
    }

    Timer {
        id: relist
        interval: 300
        onTriggered: Clipboard.refresh()
    }

    Timer {
        id: copiedFor
        interval: Theme.desktop.copiedFor
        onTriggered: widget.copied = ""
    }

    Text {
        id: title
        text: "CLIPBOARD"
        color: Colors.m3primary
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }

    ListView {
        id: list

        readonly property int row: Theme.font.normal * 2

        anchors.top: title.bottom
        anchors.topMargin: Theme.spacing.s
        anchors.bottom: parent.bottom
        width: parent.width - Theme.desktop.scrollMark - Theme.spacing.xs
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: !widget.hidesTitles
        model: widget.clips

        delegate: MouseArea {
            id: clip

            required property var modelData
            readonly property bool justCopied: widget.copied === widget.key(modelData)
            readonly property string label: modelData.image
                ? "Picture" + (modelData.image.width > 0 ? ", " + modelData.image.width + " × " + modelData.image.height : "")
                : modelData.text.replace(/\s+/g, " ").trim()

            function copy(): void {
                Clipboard.copy(modelData);
                widget.copied = widget.key(modelData);
                copiedFor.restart();
            }

            width: ListView.view.width
            height: list.row
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: copy()

            Accessible.role: Accessible.Button
            Accessible.name: "Copy " + (modelData.pinned ? "pinned: " : "") + label
            Accessible.onPressAction: copy()

            MaterialIcon {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                icon: clip.justCopied ? "check" : clip.containsMouse ? "content_copy"
                    : clip.modelData.pinned ? "push_pin" : clip.modelData.image ? "image" : "notes"
                color: clip.justCopied || clip.containsMouse ? Colors.m3primary : Colors.m3onSurfaceVariant
                font.pixelSize: Theme.icon.small
            }

            Text {
                anchors.left: icon.right
                anchors.leftMargin: Theme.spacing.s
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: clip.justCopied ? "Copied" : clip.label
                color: clip.justCopied ? Colors.m3primary : Colors.m3onSurface
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.normal
                elide: Text.ElideRight
            }
        }

        Text {
            visible: widget.clips.length === 0
            text: "Nothing copied yet"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }
    }

    ScrollMark {
        flickable: list
    }

    // On the lock screen: that there are clips, not what they say.
    Row {
        anchors.bottom: parent.bottom
        visible: widget.hidesTitles
        spacing: Theme.spacing.s

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: "lock"
            color: Colors.m3onSurfaceVariant
            font.pixelSize: Theme.icon.small
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Hidden while locked"
            color: Colors.m3onSurfaceVariant
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
        }
    }
}
