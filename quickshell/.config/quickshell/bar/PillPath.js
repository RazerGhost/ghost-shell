// The outline of one of the island's pills (bar/PillShape.qml) as an SVG path, in the shape's own
// coordinates. The body is `w` x `h` with corner radius `r`; `f` is the radius of the fillets,
// the concave curves into the screen's edges. Modes:
//   "float"  rounded all round, away from the edges.
//   "top"    the middle pill attached: flat against the top edge, rounded at the bottom, a fillet
//            on each side into the edge. The shape is w + 2f wide (the body starts at f).
//   "left"   a side pill attached: in the top-left corner, flat against the top and left edges,
//   "right"  only its inner bottom corner rounded, a fillet into the top edge beside the body and
//            one into the side edge below it. The shape is w + f wide and h + f tall ("right":
//            the body starts at f).
// Convex corners sweep clockwise (1), fillets the other way (0). Plain JavaScript, tested
// (tests/tst_pillpath.qml).
.pragma library

function n(v) {
    return Math.round(v * 100) / 100;
}

// The corner radius that fits the body (and leaves room for the fillets).
function radius(mode, w, h, r, f) {
    const room = mode === "left" || mode === "right" ? Math.min(w - f, h - f) : Math.min(w / 2, h / 2);
    return Math.max(0, Math.min(r, room));
}

function size(mode, w, h, f) {
    const side = mode === "left" || mode === "right";
    return { width: w + (mode === "top" ? f * 2 : side ? f : 0), height: h + (side ? f : 0),
             bodyX: mode === "top" || mode === "right" ? f : 0 };
}

function path(mode, w, h, r, f) {
    r = radius(mode, w, h, r, f);
    const W = size(mode, w, h, f).width;
    const arc = (rr, sweep, x, y) => `A ${n(rr)} ${n(rr)} 0 0 ${sweep} ${n(x)} ${n(y)}`;
    const p = (...parts) => parts.join(" ");
    if (mode === "top")
        return p(`M 0 0 L ${n(W)} 0`, arc(f, 0, W - f, f), `L ${n(W - f)} ${n(h - r)}`, arc(r, 1, W - f - r, h),
                 `L ${n(f + r)} ${n(h)}`, arc(r, 1, f, h - r), `L ${n(f)} ${n(f)}`, arc(f, 0, 0, 0), "Z");
    if (mode === "left")
        return p(`M 0 0 L ${n(W)} 0`, arc(f, 0, w, f), `L ${n(w)} ${n(h - r)}`, arc(r, 1, w - r, h),
                 `L ${n(f)} ${n(h)}`, arc(f, 0, 0, h + f), "Z");
    if (mode === "right")
        return p(`M 0 0 L ${n(W)} 0 L ${n(W)} ${n(h + f)}`, arc(f, 0, W - f, h), `L ${n(f + r)} ${n(h)}`,
                 arc(r, 1, f, h - r), `L ${n(f)} ${n(f)}`, arc(f, 0, 0, 0), "Z");
    return p(`M ${n(r)} 0 L ${n(w - r)} 0`, arc(r, 1, w, r), `L ${n(w)} ${n(h - r)}`, arc(r, 1, w - r, h),
             `L ${n(r)} ${n(h)}`, arc(r, 1, 0, h - r), `L 0 ${n(r)}`, arc(r, 1, r, 0), "Z");
}
