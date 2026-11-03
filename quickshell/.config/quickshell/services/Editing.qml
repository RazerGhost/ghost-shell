pragma Singleton

import Quickshell
import Quickshell.Hyprland

// Which on-screen editor is open, for what it edits to show itself for editing: the desktop
// widgets show their handles while the desktop editor is open, the dock stays shown while the
// dock and island editor is. Also the trip to an empty workspace that the desktop and the dock
// and island editors make, so no window covers what they edit.
Singleton {
    id: root

    property bool desktop: false
    property bool dock: false
    // The desktop and windows editors keep the dock out of the way: their sheet is where it
    // would be (the island stays, like Android's status bar, showing colors and sizes).
    property bool hideDock: false
    // The desktop widget the desktop editor's keyboard is on (its card in the Widgets gallery):
    // outlined on the desktop, moved with Shift + arrows ("" for none).
    property string widget: ""

    // The desktop drawn as a card while an editor is open (like GNOME's workspaces): on this
    // screen ("" while not), in this rectangle of it. The wallpaper (wallpaper/WallpaperLayer.qml)
    // and the desktop widgets (desktop/DesktopWidgets.qml) draw themselves into it, the
    // background color around it.
    property string cardScreen: ""
    property rect card: Qt.rect(0, 0, 0, 0)

    // The workspace to come back to, and the empty one gone to; 0 while not away. Kept across a
    // shell reload: one with an editor open (the editor itself is gone then) goes back home.
    property alias awayFrom: persist.awayFrom
    property alias emptyWorkspace: persist.emptyWorkspace

    PersistentProperties {
        id: persist
        reloadableId: "editing"

        property int awayFrom: 0
        property int emptyWorkspace: 0

        onReloaded: {
            if (awayFrom !== 0)
                root.back();
        }
    }

    // Who set the card last: an editor closing as the next opens (one editor straight to
    // another) is torn down after the new one set it, and only clears it if it's still its own.
    property var cardOwner: null

    function showCard(owner: var, screenName: string, rect: rect): void {
        cardOwner = owner;
        card = rect;
        cardScreen = screenName;
    }

    function hideCard(owner: var): void {
        if (cardOwner !== owner)
            return;
        cardOwner = null;
        cardScreen = "";
    }

    // Going back waits a moment: an editor opening right after (Customize.only closes one
    // editor and opens the next in one go) stays on the empty workspace instead. Going back
    // and away at once read the workspace before Hyprland had switched, so the second editor
    // took the empty one for home, and Done left you there.
    property bool backPending: false

    // Goes to a workspace past the ones in use (it's empty).
    function toEmptyWorkspace(): void {
        if (backPending) {
            backPending = false; // still there, still knowing the way home
            return;
        }
        awayFrom = Hyprland.focusedWorkspace?.id ?? 1;
        const used = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0);
        emptyWorkspace = Math.max(0, ...used) + 1;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${emptyWorkspace} })`);
    }

    function back(): void {
        if (awayFrom === 0 || backPending)
            return;
        backPending = true;
        Qt.callLater(goBack);
    }

    function goBack(): void {
        if (!backPending)
            return; // another editor opened meanwhile
        backPending = false;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${awayFrom} })`);
        awayFrom = 0;
        emptyWorkspace = 0;
    }
}
