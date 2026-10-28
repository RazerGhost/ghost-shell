import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Wayland
import qs.lock

// The login screen, run by greetd at boot (see greeter.qml and system/etc/greetd/). It looks
// like the lock screen: type the password and Enter starts Hyprland for that user.
//
// It runs as greetd's "greeter" user, which can't read your home folder, so update-greeter.sh
// gives it a copy of this shell and a snapshot of your colors, wallpaper and user name.
Scope {
    id: root

    readonly property string user: config.user
    property string message
    property bool messageIsError
    property bool busy
    // The password waiting for greetd to ask for it.
    property string pending

    signal tried()

    function login(password: string): void {
        if (!Greetd.available) {
            message = "greetd isn't running (this is a preview)";
            messageIsError = true;
            tried();
            return;
        }
        if (user === "") {
            message = "No user set up: run update-greeter.sh";
            messageIsError = true;
            tried();
            return;
        }
        pending = password;
        busy = true;
        message = "";
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        Greetd.createSession(user);
    }

    // Written by update-greeter.sh: { "user": "<your user name>" }.
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/greeter.json"
        adapter: JsonAdapter {
            id: config
            property string user: ""
        }
    }

    Connections {
        target: Greetd

        // greetd relays PAM: first it asks for the password, then maybe shows messages.
        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            if (responseRequired) {
                Greetd.respond(root.pending);
                root.pending = "";
            } else if (message !== "") {
                root.message = message;
                root.messageIsError = error;
            }
        }

        function onAuthFailure(message: string): void {
            root.busy = false;
            root.tried();
            root.message = "Wrong password";
            root.messageIsError = true;
        }

        // Start the session. true: Quickshell quits once greetd has it, and the greeter's
        // Hyprland exits after it (system/etc/greetd/hyprland.lua), so greetd can switch over.
        function onReadyToLaunch(): void {
            Greetd.launch(["start-hyprland"], [], true);
        }

        function onError(error: string): void {
            root.busy = false;
            root.tried();
            root.message = "Login failed: " + error;
            root.messageIsError = true;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-greeter"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            LockContent {
                id: content
                anchors.fill: parent
                user: root.user
                message: root.message
                messageIsError: root.messageIsError
                busy: root.busy
                onSubmitted: password => root.login(password)

                Connections {
                    target: root
                    function onTried(): void {
                        content.clear();
                    }
                }
            }
        }
    }
}
