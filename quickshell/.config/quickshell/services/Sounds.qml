pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "SoundEvents.js" as SoundEvents

// Sound events (Settings -> Sound): short sounds from the freedesktop sound theme, played with
// pw-play through the default output (so its volume and mute apply) at 60 %. Each category has
// its own switch: "notifications", "devices" (charger, USB), "feedback" (volume keys,
// screenshots) and "battery" (low battery). Notifications, the OSD, screenshots and the battery
// alerts call play(); the charger and USB devices are watched here.
Singleton {
    id: root

    readonly property real volume: 0.6
    readonly property var switches: ({
        notifications: "soundNotifications",
        devices: "soundDevices",
        feedback: "soundFeedback",
        battery: "soundBattery"
    })
    property var lastPlayed: ({}) // ms since the epoch, by sound
    // UPower reports its state shortly after the shell starts, which looks like a change; ignore
    // everything until this has fired.
    property bool ready: false

    function play(category: string, sound: string): void {
        const path = SoundEvents.file(sound);
        if (!ready || !Settings.values.soundEvents || !Settings.values[switches[category]] || path === "")
            return;
        // The same sound within 150 ms plays once (a held volume key).
        const now = Date.now();
        if (now - (lastPlayed[sound] ?? 0) < 150)
            return;
        lastPlayed[sound] = now;
        Quickshell.execDetached(["pw-play", "--volume", String(volume), path]);
    }

    // A new notification's sound: the app's choice through its hints, else a chime (critical
    // ones: the warning).
    function playNotification(hints: var, critical: bool): void {
        play("notifications", SoundEvents.forNotification(hints, critical));
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: root.ready = true
    }

    Connections {
        target: UPower

        function onOnBatteryChanged(): void {
            root.play("devices", UPower.onBattery ? "power-unplug" : "power-plug");
        }
    }

    // USB devices plugged in or out. udev has no Quickshell API, so its monitor runs while the
    // switch is on.
    Process {
        running: Settings.values.soundEvents && Settings.values.soundDevices
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=usb/usb_device"]
        stdout: SplitParser {
            onRead: line => {
                const sound = SoundEvents.forUsbLine(line);
                if (sound !== "")
                    root.play("devices", sound);
            }
        }
    }
}
