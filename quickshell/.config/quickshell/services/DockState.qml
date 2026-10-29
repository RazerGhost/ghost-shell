// Which screen the dock is showing on right now ("" while it's hidden everywhere), for things
// that sit above it: the OSD comes down closer to the edge while the dock is hidden. Set by
// dock/DockBar.qml.
pragma Singleton

import Quickshell

Singleton {
    property string shownOn: ""
}
