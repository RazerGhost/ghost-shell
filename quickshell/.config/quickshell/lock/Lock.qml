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
    // The desktop's picture (a live wallpaper's still frame): the lock screen is the desktop, locked.
    readonly property string wallpaper: Wallpaper.stillPath

    signal tried()

    function unlock(password: string): void {
        pending = password;
        busy = true;
        message = "";
        if (!pam.active)
            pam.start();
    }

    // Logged in automatically at boot and after a logout (greetd sets GHOST_AUTOLOGIN): lock
    // first, before anything else can be used. Once Hyprland confirms the lock (`secure`), a mark
    // in $XDG_RUNTIME_DIR says so and a reload loads the keybinds hyprland.lua held back. The mark
    // also keeps a restart of the shell (after a crash) from locking again. It's per Hyprland
    // instance, like hyprland.lua's: the next session after a logout must not find it.
    readonly property string lockedOnce: Quickshell.env("XDG_RUNTIME_DIR") + "/ghost-autologin-locked-"
        + (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "default")
    property bool lockingFirst: false

    Component.onCompleted: {
        if (Quickshell.env("GHOST_AUTOLOGIN") === "1")
            firstLockCheck.running = true;
    }

    Process {
        id: firstLockCheck
        command: ["test", "-e", root.lockedOnce]
        onExited: code => {
            if (code === 0)
                return; // locked once already this session
            root.lockingFirst = true;
            root.lock(false);
        }
    }

    WlSessionLock {
        id: sessionLock
        onLockedChanged: Session.locked = locked
        onSecureChanged: {
            if (!secure || !root.lockingFirst)
                return;
            root.lockingFirst = false;
            Quickshell.execDetached(["sh", "-c", 'touch "$1" && hyprctl reload', "sh", root.lockedOnce]);
        }

        WlSessionLockSurface {
            id: surface
            color: "black"

            LockContent {
                id: content
                anchors.fill: parent
                wallpaper: root.wallpaper
                // The desktop widgets show on the first screen, like the desktop's.
                showsWidgets: surface.screen === Quickshell.screens[0]
                message: root.message
                messageIsError: root.messageIsError
                busy: root.busy
                onSubmitted: password => root.unlock(password)
                onActivity: {
                    if (grace.running)
                        sessionLock.locked = false;
                }

                Connections {
                    target: root
                    function onTried(): void {
                        content.clear(root.messageIsError);
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

        // The message first: tried() shakes the field when it's an error.
        // The typed password isn't kept past its try (PAM may finish without asking for it).
        onCompleted: result => {
            root.busy = false;
            root.pending = "";
            if (result === PamResult.Success) {
                root.message = "";
                root.messageIsError = false;
                sessionLock.locked = false;
            } else {
                root.message = result === PamResult.MaxTries ? "Too many tries, wait a moment" : "Wrong password";
                root.messageIsError = true;
            }
            root.tried();
        }

        onError: error => {
            root.busy = false;
            root.pending = "";
            root.message = "Couldn't check the password (" + PamError.toString(error) + ")";
            root.messageIsError = true;
            root.tried();
        }
    }

    // `withGrace`: the idle lock, which a key or a pointer move undoes without the password
    // for Settings -> Lock screen -> Grace period (off by default). Any other lock (Super+L, the
    // power menu, before a suspend) ends a grace period that's still running.
    function lock(withGrace: bool): void {
        message = "";
        messageIsError = false;
        if (withGrace && !sessionLock.locked && Settings.values.lockGrace > 0)
            grace.restart();
        else
            grace.stop();
        sessionLock.locked = true;
    }

    Timer {
        id: grace
        interval: Settings.values.lockGrace * 1000
    }

    // Session.lock(): the power menu and the idle steps.
    Connections {
        target: Session

        function onLockRequested(grace: bool): void {
            root.lock(grace);
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock(false);
        }

        function isLocked(): bool {
            return sessionLock.locked;
        }

        // Shows the lock screen in a normal window, without locking, to check how it looks.
        // Closes after a few seconds, on Enter, or when called again.
        function preview(): void {
            preview.active = !preview.active;
        }
    }

    // Built only while shown: a whole lock screen (picture, blur, media card) that's rarely
    // looked at, and was held in memory from login on (review 2026-10-29).
    LazyLoader {
        id: preview

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-lock-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Timer {
                running: true
                interval: 8000
                onTriggered: preview.active = false
            }

            LockContent {
                id: previewContent
                anchors.fill: parent
                wallpaper: root.wallpaper
                message: "Preview: nothing is locked"
                onSubmitted: preview.active = false
            }
        }
    }
}
