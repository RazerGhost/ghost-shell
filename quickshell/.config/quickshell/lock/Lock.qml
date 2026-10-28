import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.services

// The lock screen. `qs ipc call lock lock` locks the session (Super+L, the power menu, hypridle
// when idle or before suspend); the password is checked through PAM's "login" config, the same
// as a console login. Hyprland keeps the session locked even if this crashes;
// misc.allow_session_lock_restore (look.lua) lets a new lock screen take over, see ROADMAP.md.
Scope {
    id: root

    property string message
    property bool messageIsError
    property bool busy
    // The password waiting for PAM to ask for it.
    property string pending
    readonly property string wallpaper: Wallpaper.lockPath

    signal tried()

    function unlock(password: string): void {
        pending = password;
        busy = true;
        message = "";
        if (!pam.active)
            pam.start();
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            color: "black"

            LockContent {
                id: content
                anchors.fill: parent
                wallpaper: root.wallpaper
                message: root.message
                messageIsError: root.messageIsError
                busy: root.busy
                onSubmitted: password => root.unlock(password)

                Connections {
                    target: root
                    function onTried(): void {
                        content.clear();
                    }
                }
            }
        }
    }

    PamContext {
        id: pam
        config: "login"

        // PAM asks for the password (its prompt is "Password: "); answer with what was typed.
        onResponseRequiredChanged: {
            if (responseRequired && root.pending !== "") {
                respond(root.pending);
                root.pending = "";
            }
        }

        onCompleted: result => {
            root.busy = false;
            root.tried();
            if (result === PamResult.Success) {
                root.message = "";
                sessionLock.locked = false;
            } else {
                root.message = result === PamResult.MaxTries ? "Too many tries, wait a moment" : "Wrong password";
                root.messageIsError = true;
            }
        }

        onError: error => {
            root.busy = false;
            root.tried();
            root.message = "Couldn't check the password (" + PamError.toString(error) + ")";
            root.messageIsError = true;
        }
    }

    function lock(): void {
        message = "";
        sessionLock.locked = true;
    }

    // Session.lock(): the power menu and the idle steps.
    Connections {
        target: Session

        function onLockRequested(): void {
            root.lock();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }

        function isLocked(): bool {
            return sessionLock.locked;
        }

        // Shows the lock screen in a normal window, without locking, to check how it looks.
        // Closes after a few seconds, on Enter, or when called again.
        function preview(): void {
            preview.visible = !preview.visible;
        }
    }

    PanelWindow {
        id: preview

        visible: false
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-lock-preview"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Timer {
            running: preview.visible
            interval: 8000
            onTriggered: preview.visible = false
        }

        LockContent {
            anchors.fill: parent
            wallpaper: root.wallpaper
            message: "Preview: nothing is locked"
            onSubmitted: preview.visible = false
        }
    }
}
