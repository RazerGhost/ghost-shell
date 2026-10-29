pragma Singleton

import Quickshell

// Which on-screen editor is open, for what it edits to show its editing handles (the desktop
// widgets show theirs while the desktop editor is open).
Singleton {
    property bool desktop: false
}
