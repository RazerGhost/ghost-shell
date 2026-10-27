import QtQuick
import Quickshell.Services.UPower

// power-profiles-daemon profile. Click to cycle power saver -> balanced -> performance.
// (Not named PowerProfile.qml: that would shadow UPower's PowerProfile enum.)
BarIcon {
    // Some machines have no performance profile; skip it when cycling there.
    readonly property list<int> profiles: PowerProfiles.hasPerformanceProfile
        ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
        : [PowerProfile.PowerSaver, PowerProfile.Balanced]

    icon: PowerProfiles.profile === PowerProfile.PowerSaver ? "eco"
        : PowerProfiles.profile === PowerProfile.Performance ? "speed"
        : "balance"
    label: "Power profile: " + PowerProfile.toString(PowerProfiles.profile)
    interactive: true
    onClicked: {
        const next = (profiles.indexOf(PowerProfiles.profile) + 1) % profiles.length;
        PowerProfiles.profile = profiles[next];
    }
}
