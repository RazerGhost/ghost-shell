import QtQuick
import QtTest
import "../quickshell/.config/quickshell/settings/DisplayModes.js" as DisplayModes

TestCase {
    name: "DisplayModes"

    function test_modes() {
        compare(DisplayModes.modes(["1280x720@165.00Hz", "1920x1080@60.00Hz", "1920x1080@165.00Hz", "1920x1080@164.99Hz", "junk"]), [
            { mode: "1920x1080@165", label: "1920 × 1080, 165 Hz" },
            { mode: "1920x1080@60", label: "1920 × 1080, 60 Hz" },
            { mode: "1280x720@165", label: "1280 × 720, 165 Hz" }
        ]);
    }

    function test_current() {
        const laptop = { width: 1920, height: 1080, refreshRate: 165.002, scale: 1, transform: 0 };
        compare(DisplayModes.current(laptop, undefined), { mode: "1920x1080@165", scale: 1, transform: 0, vrr: 2 });
        compare(DisplayModes.current(laptop, 0).vrr, 0);
    }

    function test_lua() {
        compare(DisplayModes.lua("eDP-1", { mode: "1920x1080@165", scale: 1.25, transform: 0, vrr: 2 }),
                'hl.monitor({ output = "eDP-1", mode = "1920x1080@165", position = "auto", scale = 1.25, transform = 0, vrr = 2 })');
        // Anything odd (a hand-edited settings file) gives nothing rather than broken Lua.
        compare(DisplayModes.lua('eDP-1" })', { mode: "1920x1080@165", scale: 1, transform: 0, vrr: 2 }), "");
        compare(DisplayModes.lua("eDP-1", { mode: "huge", scale: 1, transform: 0, vrr: 2 }), "");
        compare(DisplayModes.lua("eDP-1", { mode: "1920x1080@165", scale: 9, transform: 0, vrr: 2 }), "");
        // Turned off, and showing another screen.
        compare(DisplayModes.lua("eDP-1", { disabled: true }), 'hl.monitor({ output = "eDP-1", disabled = true })');
        compare(DisplayModes.lua("HDMI-A-1", { mode: "2560x1440@60", scale: 1, transform: 0, vrr: 2, mirror: "eDP-1" }),
                'hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@60", position = "auto", scale = 1, transform = 0, vrr = 2, mirror = "eDP-1" })');
        compare(DisplayModes.lua("HDMI-A-1", { mode: "2560x1440@60", scale: 1, transform: 0, vrr: 2, mirror: 'x" })' }), "");
    }

    readonly property var laptopScreen: ({ name: "eDP-1", width: 1920, height: 1080, refreshRate: 165.002, scale: 1, transform: 0,
                                            availableModes: ["1920x1080@165.00Hz", "1920x1080@60.00Hz", "1280x720@165.00Hz"] })
    readonly property var external: ({ name: "HDMI-A-1", width: 2560, height: 1440, refreshRate: 59.95, scale: 1, transform: 0,
                                        availableModes: ["2560x1440@59.95Hz"] })

    function test_rates() {
        compare(DisplayModes.rates(laptopScreen), [165, 60]);   // only at 1920 x 1080
        compare(DisplayModes.rates(null), []);
        compare(DisplayModes.withRate({ mode: "1920x1080@165", scale: 1 }, 60), { mode: "1920x1080@60", scale: 1 });
        compare(DisplayModes.laptop([external, laptopScreen]), laptopScreen);
        compare(DisplayModes.laptop([external]), null);
    }

    function test_workspaceRules() {
        // One screen: nothing.
        compare(DisplayModes.workspaceRules("eDP-1", [laptopScreen]), []);
        const right = Object.assign({}, external, { x: 1920, y: 0 });
        const left = { name: "DP-2", x: -2560, y: 0 };
        const lines = DisplayModes.workspaceRules("eDP-1", [right, laptopScreen, left]);
        compare(lines.length, 15);
        // The main screen first (1-5), then left to right: DP-2 6-10, HDMI-A-1 11-15.
        compare(lines[0], 'hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })');
        compare(lines[4], 'hl.workspace_rule({ workspace = "5", monitor = "eDP-1" })');
        compare(lines[5], 'hl.workspace_rule({ workspace = "6", monitor = "DP-2", default = true })');
        compare(lines[10], 'hl.workspace_rule({ workspace = "11", monitor = "HDMI-A-1", default = true })');
        // The main screen chosen otherwise, a screen that's off left out.
        const off = Object.assign({}, right, { disabled: true });
        compare(DisplayModes.workspaceRules("DP-2", [laptopScreen, left, off])[0], 'hl.workspace_rule({ workspace = "1", monitor = "DP-2", default = true })');
        compare(DisplayModes.workspaceRules("DP-2", [laptopScreen, left, off]).length, 10);
    }

    function test_effective() {
        const saved = { "eDP-1": { mode: "1920x1080@165", scale: 1.25, transform: 0, vrr: 0 } };
        // Plugged in: as saved.
        compare(DisplayModes.effective(saved, [laptopScreen], { onBattery: false, lowOnBattery: true }), saved);
        // On battery with the rule: the lowest rate, the rest of the saved setup kept.
        compare(DisplayModes.effective(saved, [laptopScreen], { onBattery: true, lowOnBattery: true })["eDP-1"],
                { mode: "1920x1080@60", scale: 1.25, transform: 0, vrr: 0 });
        // Nothing saved: from the screen as it is.
        compare(DisplayModes.effective({}, [laptopScreen], { onBattery: true, lowOnBattery: true })["eDP-1"].mode, "1920x1080@60");
        // Without the rule, nothing changes on battery.
        compare(DisplayModes.effective({}, [laptopScreen], { onBattery: true, lowOnBattery: false }), {});
        // A second screen: only it, only the laptop, or a copy of the laptop's.
        compare(DisplayModes.effective({}, [laptopScreen, external], { project: "external" }), { "eDP-1": { disabled: true } });
        compare(DisplayModes.effective({}, [laptopScreen, external], { project: "laptop" }), { "HDMI-A-1": { disabled: true } });
        compare(DisplayModes.effective({}, [laptopScreen, external], { project: "mirror" })["HDMI-A-1"].mirror, "eDP-1");
        compare(DisplayModes.effective({}, [laptopScreen, external], { project: "extend" }), {});
        // No second screen: the laptop's screen is never turned off.
        compare(DisplayModes.effective({}, [laptopScreen], { project: "external" }), {});
        // The saved list itself is never changed.
        DisplayModes.effective(saved, [laptopScreen], { onBattery: true, lowOnBattery: true });
        compare(saved["eDP-1"].mode, "1920x1080@165");
    }
}
