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

    // The workspace to come back to; 0 while not away.
    property int awayFrom: 0

    // Goes to a workspace past the ones in use (it's empty).
    function toEmptyWorkspace(): void {
        awayFrom = Hyprland.focusedWorkspace?.id ?? 1;
        const used = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0);
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${Math.max(0, ...used) + 1} })`);
    }

    function back(): void {
        if (awayFrom === 0)
            return;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${awayFrom} })`);
        awayFrom = 0;
    }
}
