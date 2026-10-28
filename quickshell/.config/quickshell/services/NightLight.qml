// Night light through hyprsunset: warmer colors to go easy on the eyes in the evening.
//
// hyprsunset follows a schedule (hypr/hyprsunset.conf) and tells us when it switches profile
// (`qs ipc call nightlight refresh`). It can't report a manual override, so `on` is read from
// the active profile at startup and on every switch, and set directly when toggled here.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "NightLightProfile.js" as NightLightProfile

Singleton {
    id: root

    property bool on: false
    // Same as the evening profile in hypr/hyprsunset.conf.
    readonly property int temperature: 4000

    function toggle(): void {
        on = !on;
        Quickshell.execDetached(on ? ["hyprctl", "hyprsunset", "temperature", String(temperature)]
                                   : ["hyprctl", "hyprsunset", "identity"]);
    }

    Process {
        id: read
        command: ["hyprctl", "hyprsunset", "profile"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.on = NightLightProfile.warm(text);
                    retry.attempts = 0;
                } catch (e) {
                    // hyprsunset starts alongside the shell at login and may not be up yet.
                    if (retry.attempts < 5) {
                        retry.attempts++;
                        retry.start();
                    } else {
                        console.warn("NightLight: hyprsunset isn't answering: " + e.message);
                    }
                }
            }
        }
    }

    Timer {
        id: retry
        property int attempts: 0
        interval: 2000
        onTriggered: read.running = true
    }

    IpcHandler {
        target: "nightlight"

        function refresh(): void {
            read.running = true;
        }
    }
}
