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

    // Goes to a workspace past the ones in use (it's empty).
    function toEmptyWorkspace(): void {
        awayFrom = Hyprland.focusedWorkspace?.id ?? 1;
        const used = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0);
        emptyWorkspace = Math.max(0, ...used) + 1;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${emptyWorkspace} })`);
    }

    function back(): void {
        if (awayFrom === 0)
            return;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${awayFrom} })`);
        awayFrom = 0;
        emptyWorkspace = 0;
    }
}
