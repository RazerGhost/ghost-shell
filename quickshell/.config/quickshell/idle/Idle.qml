import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.services

// What happens when you stop using the laptop: dim, lock, screen off, suspend, each after its
// own number of minutes without input (settings window; separate times on battery and plugged
// in, switching as soon as you plug in or out). Apps that keep the screen awake (a playing
// video) hold these off. Locking before a suspend is hypridle's job (hypr/hypridle.conf).
Scope {
    id: root

    readonly property string power: UPower.onBattery ? "Battery" : "Ac"

    // One step: active after `minutes` without input (0 = never); `idle` turns false again on
    // the next input.
    component Step: IdleMonitor {
        required property int minutes
        enabled: minutes > 0
        timeout: minutes * 60
    }

    Step {
        minutes: Settings.values["idle" + root.power + "Dim"]
        onIsIdleChanged: Quickshell.execDetached(isIdle ? ["brightnessctl", "-s", "set", "10%"]
                                                        : ["brightnessctl", "-r"])
    }

    Step {
        minutes: Settings.values["idle" + root.power + "Lock"]
        // Straight to the lock screen, not through hypridle (loginctl lock-session), so it
        // also locks if hypridle isn't running.
        onIsIdleChanged: {
            if (isIdle)
                Session.lock();
        }
    }

    Step {
        minutes: Settings.values["idle" + root.power + "ScreenOff"]
        onIsIdleChanged: Quickshell.execDetached(isIdle
            ? ["hyprctl", "dispatch", "hl.dsp.dpms({ action = \"disable\" })"]
            : ["sh", "-c", "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })' && brightnessctl -r"])
    }

    Step {
        minutes: Settings.values["idle" + root.power + "Suspend"]
        onIsIdleChanged: {
            if (isIdle)
                Session.suspend();
        }
    }
}
