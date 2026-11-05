// Whether this machine's snapshots can be listed: the snapshots module set snapper up for your
// user (ALLOW_USERS). CachyOS has snapper and its config for / on every machine, but without the
// module your user can't list them, so Settings' Snapshots page would only say so: Settings and
// the launcher's search leave it out then (SettingsPages.available). Asked once at start.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false

    Process {
        running: true
        command: ["snapper", "-c", "root", "list"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => root.available = code === 0
    }
}
