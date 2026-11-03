// The outline of the island (bar/PillShape.qml) as an SVG path, in the shape's own coordinates.
// The body is `w` x `h` with corner radius `r`; `f` is the radius of the fillets, the concave
// curves into the top edge. Modes:
//   "float"  rounded all round, away from the edge.
//   "top"    attached: flat against the top edge, rounded at the bottom, a fillet on each side
//            into the edge. The shape is w + 2f wide (the body starts at f).
// Convex corners sweep clockwise (1), fillets the other way (0). Plain JavaScript, tested
// (tests/tst_pillpath.qml).
.pragma library

function n(v) {
    return Math.round(v * 100) / 100;
}

// The corner radius that fits the body.
function radius(w, h, r) {
    return Math.max(0, Math.min(r, w / 2, h / 2));
}

function size(mode, w, h, f) {
    return { width: w + (mode === "top" ? f * 2 : 0), height: h, bodyX: mode === "top" ? f : 0 };
}

function path(mode, w, h, r, f) {
    r = radius(w, h, r);
    const W = size(mode, w, h, f).width;
    const arc = (rr, sweep, x, y) => `A ${n(rr)} ${n(rr)} 0 0 ${sweep} ${n(x)} ${n(y)}`;
    const p = (...parts) => parts.join(" ");
    if (mode === "top")
        return p(`M 0 0 L ${n(W)} 0`, arc(f, 0, W - f, f), `L ${n(W - f)} ${n(h - r)}`, arc(r, 1, W - f - r, h),
                 `L ${n(f + r)} ${n(h)}`, arc(r, 1, f, h - r), `L ${n(f)} ${n(f)}`, arc(f, 0, 0, 0), "Z");
    return p(`M ${n(r)} 0 L ${n(w - r)} 0`, arc(r, 1, w, r), `L ${n(w)} ${n(h - r)}`, arc(r, 1, w - r, h),
             `L ${n(r)} ${n(h)}`, arc(r, 1, 0, h - r), `L 0 ${n(r)}`, arc(r, 1, r, 0), "Z");
}
