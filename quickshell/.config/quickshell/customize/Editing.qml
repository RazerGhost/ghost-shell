pragma Singleton

import Quickshell

// Which on-screen editor is open, for what it edits to show itself for editing: the desktop
// widgets show their handles while the desktop editor is open, the dock stays shown while the
// dock and island editor is.
Singleton {
    property bool desktop: false
    property bool dock: false
}
