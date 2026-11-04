import QtQuick

// The keyboard for a desktop widget's text field (the to-do widgets' "Add a task", the note).
// The desktop's layer takes no keyboard (DesktopWidgets.qml), so a click in a field asks for it:
// `wantsKeyboard` makes the layer take it (Exclusive) and, once its window is active
// (`hasKeyboard`), only keep it (OnDemand) until a click elsewhere, which ends the typing
// (`stopped`). The item's own focus says nothing about the keyboard: it's set before the layer
// has it; the window being active does (NOTES). Put it inside the widget, and call start() on a
// click in the field, stop() on Escape or when done.
Item {
    id: root

    property bool wantsKeyboard: false
    property bool hasKeyboard: false

    // The typing ended: put the field back (clear it, drop its focus).
    signal stopped()

    function start(): void {
        wantsKeyboard = true;
        // The layer may have the keyboard already (another widget was typed in): then there's
        // no change of window focus to wait for.
        if (Window.active)
            hasKeyboard = true;
    }

    function stop(): void {
        wantsKeyboard = false;
        hasKeyboard = false;
        stopped();
    }

    // Asked for and never given (the layer refused): give up rather than wait.
    Timer {
        running: root.wantsKeyboard && !root.hasKeyboard
        interval: 1000
        onTriggered: root.stop()
    }

    Connections {
        target: root.Window
        function onActiveChanged(): void {
            if (!root.wantsKeyboard)
                return;
            if (root.Window.active)
                root.hasKeyboard = true;
            else if (root.hasKeyboard)
                root.stop();
        }
    }
}
