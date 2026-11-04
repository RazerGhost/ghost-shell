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

    function startTyping(): void {
        keyboard.start();
        note.forceActiveFocus();
        note.cursorPosition = note.text.length;
    }

    // Keyboard mode: Enter starts typing.
    function key(event: var): bool {
        if (hidesTitles || (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter))
            return false;
        startTyping();
        return true;
    }

    WidgetKeyboard {
        id: keyboard
        onStopped: {
            note.focus = false;
            note.text = Planner.note;
            page.contentY = 0;
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

    // The note, scrolled with the wheel or touchpad; while typing it follows the cursor (a click
    // puts it at the end). Not dragged: a drag in the text selects. Back to the top when typing
    // stops.
    Flickable {
        id: page

        function scroll(event: var): void {
            const step = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * Theme.font.normal * 3;
            contentY = Math.max(0, Math.min(contentY - step, contentHeight - height));
        }

        function ensureVisible(r: rect): void {
            if (contentY > r.y)
                contentY = r.y;
            else if (contentY + height < r.y + r.height)
                contentY = r.y + r.height - height;
        }

        anchors.top: title.bottom
        anchors.topMargin: Theme.spacing.s
        anchors.bottom: parent.bottom
        width: parent.width - Theme.desktop.scrollMark - Theme.spacing.xs
        contentHeight: note.height
        clip: true
        interactive: false
        visible: !widget.hidesTitles

        WheelHandler {
            onWheel: event => page.scroll(event)
        }

        TextEdit {
            id: note
            width: parent.width
            onCursorRectangleChanged: {
                if (keyboard.wantsKeyboard)
                    page.ensureVisible(cursorRectangle);
            }
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
    }

    ScrollMark {
        flickable: page
    }

    // The click asks for the keyboard (the note can't have it before the layer does). Not in
    // the desktop editor: its widgets are being placed there. Over the whole note, so a click
    // below a short one counts; the wheel scrolls the note from here too.
    MouseArea {
        anchors.fill: page
        visible: page.visible && !keyboard.wantsKeyboard && !Editing.desktop
        cursorShape: Qt.IBeamCursor
        onClicked: widget.startTyping()
        onWheel: wheel => page.scroll(wheel)
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
