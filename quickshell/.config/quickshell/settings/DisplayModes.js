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
// transform 0-7 (rotations and flips); vrr 0-3. A screen turned off (quick settings' Display
// page, a second screen only) is { disabled: true }; one showing another (duplicate) has
// `mirror`, that screen's name.
function lua(output, setup) {
    const name = /^[A-Za-z0-9_.-]+$/;
    if (!name.test(output))
        return "";
    if (setup.disabled === true)
        return `hl.monitor({ output = "${output}", disabled = true })`;
    if (setup.mirror !== undefined && !name.test(String(setup.mirror)))
        return "";
    const ok = /^\d+x\d+@\d+(\.\d+)?$/.test(setup.mode)
        && typeof setup.scale === "number" && setup.scale >= 0.5 && setup.scale <= 3
        && Number.isInteger(setup.transform) && setup.transform >= 0 && setup.transform <= 7
        && Number.isInteger(setup.vrr) && setup.vrr >= 0 && setup.vrr <= 3;
    if (!ok)
        return "";
    return `hl.monitor({ output = "${output}", mode = "${setup.mode}", position = "auto", `
        + `scale = ${setup.scale}, transform = ${setup.transform}, vrr = ${setup.vrr}`
        + (setup.mirror !== undefined ? `, mirror = "${setup.mirror}"` : "") + " })";
}

// The laptop's own screen among `hyprctl monitors all -j`'s entries (eDP, or LVDS on old ones);
// null on a desktop.
function laptop(monitors) {
    return Array.from(monitors ?? []).find(m => /^(eDP|LVDS)/.test(m.name)) ?? null;
}

// The refresh rates (Hz, rounded, highest first) a screen offers at its current resolution.
function rates(monitor) {
    const out = [];
    for (const m of Array.from(monitor?.availableModes ?? [])) {
        const match = String(m).match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
        if (match && Number(match[1]) === monitor.width && Number(match[2]) === monitor.height) {
            const hz = Math.round(Number(match[3]));
            if (!out.includes(hz))
                out.push(hz);
        }
    }
    return out.sort((a, b) => b - a);
}

// `setup` (from current() or saved) at another refresh rate, the resolution kept.
function withRate(setup, hz) {
    return Object.assign({}, setup, { mode: String(setup.mode).replace(/@[\d.]+$/, "@" + hz) });
}

// The screens' setups for shell-settings.lua at this moment: your saved ones (Settings ->
// Display, the Display page's refresh rate), then while on battery with "lower refresh rate on
// battery" the laptop's screen at its lowest rate (your choice stays saved for when it's plugged
// in), then, with a second screen connected, the projection: "extend" (as set up), "mirror" (the
// other screens show the laptop's), "external" (the laptop's screen off) or "laptop" (the others
// off). Without a second screen there's no projection, so the laptop's screen is never left off.
// `monitors` is `hyprctl monitors all -j` (with the disabled ones); `opts` { onBattery,
// lowOnBattery, project }.
function effective(saved, monitors, opts) {
    const out = {};
    for (const [output, setup] of Object.entries(saved ?? {}))
        out[output] = setup;
    const list = Array.from(monitors ?? []);
    const own = laptop(list);
    const o = opts ?? {};
    if (own && o.onBattery === true && o.lowOnBattery === true) {
        const lowest = rates(own).slice(-1)[0];
        if (lowest !== undefined)
            out[own.name] = withRate(out[own.name] ?? current(own, undefined), lowest);
    }
    const others = list.filter(m => m !== own);
    if (own && others.length > 0) {
        if (o.project === "external")
            out[own.name] = { disabled: true };
        for (const other of others) {
            if (o.project === "laptop")
                out[other.name] = { disabled: true };
            else if (o.project === "mirror" && other.width > 0)
                out[other.name] = Object.assign({}, out[other.name] ?? current(other, undefined), { mirror: own.name });
        }
    }
    return out;
}
