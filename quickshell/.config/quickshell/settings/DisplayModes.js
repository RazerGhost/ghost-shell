// Settings' Display page: a screen's modes from Hyprland (`hyprctl monitors -j`), its
// current setup, and the Lua that sets it (`hl.monitor`), used both to try a change live and in
// the generated shell-settings.lua (HyprlandConfig.js). Plain JavaScript, so it can be tested on
// its own (tests/tst_displaymodes.qml).
.pragma library

// Hyprland's "1920x1080@165.00Hz" as { mode: "1920x1080@165", label: "1920 × 1080, 165 Hz" },
// highest resolution first, then highest refresh; duplicates after rounding go.
function modes(available) {
    const result = [];
    for (const m of available) {
        const match = m.match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
        if (!match)
            continue;
        const [w, h, hz] = [Number(match[1]), Number(match[2]), Math.round(Number(match[3]))];
        const mode = `${w}x${h}@${hz}`;
        if (!result.some(r => r.mode === mode))
            result.push({ mode: mode, label: `${w} × ${h}, ${hz} Hz`, pixels: w * h, hz: hz });
    }
    return result.sort((a, b) => b.pixels - a.pixels || b.hz - a.hz)
        .map(r => ({ mode: r.mode, label: r.label }));
}

// A screen's current setup from its `hyprctl monitors -j` entry: { mode, scale, transform, vrr }.
// vrr: 0 off, 1 always, 2 fullscreen only (what the saved setting holds; Hyprland reports only
// whether it's active right now).
function current(monitor, savedVrr) {
    return {
        mode: `${monitor.width}x${monitor.height}@${Math.round(monitor.refreshRate)}`,
        scale: monitor.scale,
        transform: monitor.transform,
        vrr: typeof savedVrr === "number" ? savedVrr : 2
    };
}

// The `hl.monitor` call for one screen, or "" when anything in it isn't safe to put in Lua (a
// hand-edited settings file): names are letters, digits and -_. ; modes WxH@Hz; scale 0.5-3;
// transform 0-7 (rotations and flips); vrr 0-3.
function lua(output, setup) {
    const ok = /^[A-Za-z0-9_.-]+$/.test(output)
        && /^\d+x\d+@\d+(\.\d+)?$/.test(setup.mode)
        && typeof setup.scale === "number" && setup.scale >= 0.5 && setup.scale <= 3
        && Number.isInteger(setup.transform) && setup.transform >= 0 && setup.transform <= 7
        && Number.isInteger(setup.vrr) && setup.vrr >= 0 && setup.vrr <= 3;
    if (!ok)
        return "";
    return `hl.monitor({ output = "${output}", mode = "${setup.mode}", position = "auto", `
        + `scale = ${setup.scale}, transform = ${setup.transform}, vrr = ${setup.vrr} })`;
}
