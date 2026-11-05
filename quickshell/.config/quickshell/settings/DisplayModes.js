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
// hand-edited settings file): outputs are names (letters, digits and -_.) or a monitor's
// description (`desc:` and letters, digits, spaces and .,()/+-_ : Hyprland matches the physical
// monitor by it, whichever port it's on); modes WxH@Hz; scale 0.5-3; transform 0-7 (rotations
// and flips); vrr 0-3; position "auto" or XxY. A screen turned off (quick settings' Display page,
// a second screen only) is { disabled: true }; one showing another (duplicate) has `mirror`,
// that screen's name.
function lua(output, setup) {
    const name = /^[A-Za-z0-9_.-]+$/;
    if (!name.test(output) && !/^desc:[A-Za-z0-9 _.,()\/+-]+$/.test(output))
        return "";
    if (setup.disabled === true)
        return `hl.monitor({ output = "${output}", disabled = true })`;
    if (setup.mirror !== undefined && !name.test(String(setup.mirror)))
        return "";
    const position = setup.position ?? "auto";
    const ok = /^\d+x\d+@\d+(\.\d+)?$/.test(setup.mode)
        && (position === "auto" || /^-?\d+x-?\d+$/.test(position))
        && typeof setup.scale === "number" && setup.scale >= 0.5 && setup.scale <= 3
        && Number.isInteger(setup.transform) && setup.transform >= 0 && setup.transform <= 7
        && Number.isInteger(setup.vrr) && setup.vrr >= 0 && setup.vrr <= 3;
    if (!ok)
        return "";
    return `hl.monitor({ output = "${output}", mode = "${setup.mode}", position = "${position}", `
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
    // The connected screens' saved setups by output name (saved under a monitor's description
    // too), with this set of screens' arrangement (`opts.layouts`, screenLayouts).
    const layout = list.length > 1 ? (o.layouts ?? {})[setKey(list)] : undefined;
    for (const m of list) {
        const setup = savedFor(saved, m);
        const position = layout?.[key(m)];
        if (setup || position)
            out[m.name] = Object.assign({}, setup ?? current(m, undefined), position ? { position: position } : {});
    }
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

// Workspaces per screen (Settings -> Display): the main screen 1-5, the next screen (left to
// right) 6-10, a third 11-15; each screen opens on the first of its own. Hyprland's workspace
// rules as Lua lines; none with one screen. `main` is the main screen's output name, `monitors`
// `hyprctl monitors all -j`'s entries.
function workspaceRules(main, monitors) {
    const list = Array.from(monitors ?? []).filter(m => !m.disabled && /^[A-Za-z0-9_.-]+$/.test(m.name));
    if (list.length < 2)
        return [];
    const first = list.find(m => m.name === main) ?? list[0];
    const order = [first, ...list.filter(m => m !== first).sort((a, b) => a.x - b.x || a.y - b.y)];
    const lines = [];
    order.forEach((m, i) => {
        for (let n = 1; n <= 5; n++) {
            const ws = i * 5 + n;
            lines.push(`hl.workspace_rule({ workspace = "${ws}", monitor = "${m.name}"${n === 1 ? ", default = true" : ""} })`);
        }
    });
    return lines;
}

// The key a screen's setup is saved under: the monitor's description (make, model, serial) when
// it has one, so a monitor gets its setup back on any port, else its output name (the laptop's
// own screen, a virtual one).
function key(monitor) {
    const d = String(monitor?.description ?? "").trim();
    return d !== "" && /^[A-Za-z0-9 _.,()\/+-]+$/.test(d) && !/^(eDP|LVDS)/.test(monitor.name) ? "desc:" + d : String(monitor?.name ?? "");
}

// The saved setup for a connected screen: under its key, else under its output name (saved
// before keys).
function savedFor(saved, monitor) {
    return saved?.[key(monitor)] ?? saved?.[monitor.name];
}

// Which screens are connected, as one key for their arrangement (sorted, so the order they
// were found in doesn't matter): each set of screens keeps its own (screenLayouts).
function setKey(monitors) {
    return Array.from(monitors ?? []).map(key).sort().join(" | ");
}

// A screen's size on the desktop, in Hyprland's layout pixels: its mode over its scale, turned
// a quarter for rotations 1, 3, 5 and 7.
function logicalSize(monitor) {
    const s = monitor.scale > 0 ? monitor.scale : 1;
    const w = Math.round(monitor.width / s), h = Math.round(monitor.height / s);
    return monitor.transform % 2 === 1 ? { w: h, h: w } : { w: w, h: h };
}

// A screen dragged to (x, y) in the arrangement lines up beside another: rects
// [{ key, x, y, w, h }] (layout pixels), `moved` the dragged one's key. It goes against the
// nearest side of the nearest other screen (its left, right, top or bottom), its other edge
// lined up with that screen's start, middle or end when within `reach`, and always sharing at
// least a quarter of the shorter side (a corner alone, the pointer can't cross); the first screen (the main one) stays at 0, 0 and the others are given relative to it.
// { key: "XxY" }.
function arranged(rects, moved, x, y, reach) {
    const list = Array.from(rects);
    const me = list.find(r => r.key === moved);
    if (!me)
        return {};
    let best = null;
    for (const o of list.filter(r => r !== me)) {
        const candidates = [
            { x: o.x - me.w, y: y, side: "y" },      // left of it
            { x: o.x + o.w, y: y, side: "y" },       // right of it
            { x: x, y: o.y - me.h, side: "x" },      // above it
            { x: x, y: o.y + o.h, side: "x" }        // below it
        ];
        for (const c of candidates) {
            if (c.side === "y") {
                const lines = [o.y, o.y + (o.h - me.h) / 2, o.y + o.h - me.h];
                const near = lines.find(l => Math.abs(l - c.y) <= reach);
                const share = Math.min(me.h, o.h) / 4; // the pointer crosses where they meet
                c.y = Math.round(Math.min(Math.max(near ?? c.y, o.y - me.h + share), o.y + o.h - share));
            } else {
                const lines = [o.x, o.x + (o.w - me.w) / 2, o.x + o.w - me.w];
                const near = lines.find(l => Math.abs(l - c.x) <= reach);
                const share = Math.min(me.w, o.w) / 4;
                c.x = Math.round(Math.min(Math.max(near ?? c.x, o.x - me.w + share), o.x + o.w - share));
            }
            const d = Math.hypot(c.x - x, c.y - y);
            if (!best || d < best.d)
                best = { x: c.x, y: c.y, d: d };
        }
    }
    const placed = list.map(r => r === me ? Object.assign({}, r, { x: best ? best.x : x, y: best ? best.y : y }) : r);
    const origin = placed[0];
    const out = {};
    for (const r of placed)
        out[r.key] = `${Math.round(r.x - origin.x)}x${Math.round(r.y - origin.y)}`;
    return out;
}
