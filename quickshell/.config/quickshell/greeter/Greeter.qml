import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Wayland
import qs.lock
import qs.services

// The login screen, run by greetd at boot (see greeter.qml and system/etc/greetd/). It looks
// like the lock screen: type the password and Enter starts Hyprland for that user.
//
// It runs as greetd's "greeter" user, which can't read your home folder, so modules/core/greeter.sh
// gives it a copy of this shell and your user name, and greeter/sync.sh keeps a copy of your
// settings, colors and the lock screen's picture where it can read them.
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
            message = "No user set up: run ghost greeter";
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

    readonly property string face: "/var/lib/qs-greeter/shared/face"
    property bool hasFace: false

    Process {
        command: ["test", "-f", root.face]
        running: true
        onExited: code => root.hasFace = code === 0
    }

    // Written by modules/core/greeter.sh: { "user": "<your user name>" }.
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

        // The message first: tried() shakes the field when it's an error.
        function onAuthFailure(message: string): void {
            root.busy = false;
            root.message = "Wrong password";
            root.messageIsError = true;
            root.tried();
        }

        // Start the session. true: Quickshell quits once greetd has it, and the greeter's
        // Hyprland exits after it (system/etc/greetd/hyprland.lua), so greetd can switch over.
        function onReadyToLaunch(): void {
            Greetd.launch(["start-hyprland"], [], true);
        }

        function onError(error: string): void {
            root.busy = false;
            root.message = "Login failed: " + error;
            root.messageIsError = true;
            root.tried();
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
                // Its own copy of the lock screen's picture (greeter/sync.sh).
                wallpaper: Wallpaper.path
                user: Settings.values.greeterShowName ? root.user : ""
                // Your ~/.face, copied by greeter/sync.sh.
                face: root.hasFace ? root.face : ""
                powerButtons: Settings.values.greeterPowerButtons
                message: root.message
                messageIsError: root.messageIsError
                busy: root.busy
                onSubmitted: password => root.login(password)

                Connections {
                    target: root
                    function onTried(): void {
                        content.clear(root.messageIsError);
                    }
                }
            }
        }
    }
}
