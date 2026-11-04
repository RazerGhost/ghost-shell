import QtQuick
import qs.services
import qs.theme
import qs.widgets

// The note widget (medium), like a sticky note: the today menu's note (services/Planner.qml),
// written straight on the desktop. A click in it takes the keyboard (WidgetKeyboard.qml); what's
// typed is saved as you go, until Escape or a click in a window. On the lock screen
// (`hidesTitles`) it keeps the note to itself.
WidgetSurface {
    id: widget

    medium: true
    property bool hidesTitles: false
    readonly property alias keyboard: keyboard

    WidgetKeyboard {
        id: keyboard
        onStopped: {
            note.focus = false;
            note.text = Planner.note;
        }
    }

    Text {
        id: title
        text: "NOTE"
        color: Colors.m3primary
        font.family: Theme.font.sans
        font.pixelSize: Theme.font.small
        font.weight: Font.DemiBold
        font.letterSpacing: 1
    }

    // The note, cut off at the card's foot (the today menu shows all of it). While typing it
    // scrolls so the line with the cursor shows (a click puts the cursor at the end).
    Item {
        id: page
        readonly property real scroll: keyboard.wantsKeyboard
            ? Math.max(0, note.cursorRectangle.y + note.cursorRectangle.height - height) : 0

        anchors.top: title.bottom
        anchors.topMargin: Theme.spacing.s
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        visible: !widget.hidesTitles

        TextEdit {
            id: note
            y: -page.scroll
            width: parent.width
            text: Planner.note
            wrapMode: TextEdit.Wrap
            color: Colors.m3onSurface
            selectionColor: Colors.m3primary
            selectedTextColor: Colors.m3onPrimary
            font.family: Theme.font.sans
            font.pixelSize: Theme.font.normal
            readOnly: !keyboard.wantsKeyboard

            Accessible.role: Accessible.EditableText
            Accessible.name: "Note"

            // Saved while typing; a change made elsewhere (the today menu) shows here.
            onTextChanged: {
                if (keyboard.wantsKeyboard)
                    Planner.setNote(text);
            }
            Keys.onEscapePressed: keyboard.stop()

            Connections {
                target: Planner
                function onNoteChanged(): void {
                    if (!keyboard.wantsKeyboard && note.text !== Planner.note)
                        note.text = Planner.note;
                }
            }
        }

        Text {
            anchors.fill: note
            visible: note.text === ""
            text: "Write something down"
            color: Colors.m3onSurfaceVariant
            font: note.font
        }

        // The click asks for the keyboard (the note can't have it before the layer does). Not in
        // the desktop editor: its widgets are being placed there.
        MouseArea {
            anchors.fill: parent
            visible: !keyboard.wantsKeyboard && !Editing.desktop
            cursorShape: Qt.IBeamCursor
            onClicked: {
                keyboard.start();
                note.forceActiveFocus();
                note.cursorPosition = note.text.length;
            }
        }
    }

    // On the lock screen: that there's a note, not what it says.
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
