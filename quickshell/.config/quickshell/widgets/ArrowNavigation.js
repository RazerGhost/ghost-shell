// Moving the keyboard focus with the arrow keys, for widgets/ArrowNavigation.qml: to the nearest
// control in that direction, like a TV remote. Plain JavaScript, so it can be tested on its own
// (tests/tst_arrownavigation.qml).
.pragma library

// Which of `candidates` ({ x, y, width, height }) is next from `from` going `direction` ("left",
// "right", "up" or "down"): its index, or -1 when there's nothing that way. Controls in line
// with `from` (overlapping it across the direction) come first, the nearest of them; the cross
// distance only breaks ties within a row or column. Others only within 45 degrees of the
// direction, so Left never jumps to a control below. With no `from` (nothing focused yet), the
// first in reading order.
function nearest(from, candidates, direction) {
    if (!from) {
        let first = -1;
        candidates.forEach((c, i) => {
            const f = candidates[first];
            if (first < 0 || c.y < f.y || (c.y === f.y && c.x < f.x))
                first = i;
        });
        return first;
    }
    const horizontal = direction === "left" || direction === "right";
    const sign = direction === "right" || direction === "down" ? 1 : -1;
    const center = r => horizontal ? r.x + r.width / 2 : r.y + r.height / 2;
    const crossCenter = r => horizontal ? r.y + r.height / 2 : r.x + r.width / 2;
    const start = r => horizontal ? r.x : r.y;
    const end = r => horizontal ? r.x + r.width : r.y + r.height;
    const crossStart = r => horizontal ? r.y : r.x;
    const crossEnd = r => horizontal ? r.y + r.height : r.x + r.width;

    let best = -1;
    let bestScore = Infinity;
    candidates.forEach((c, i) => {
        // Beyond `from`'s center that way (a button inside a row counts as right of it).
        if ((center(c) - center(from)) * sign <= 0)
            return;
        const gap = Math.max(0, sign > 0 ? start(c) - end(from) : start(from) - end(c));
        const inLine = Math.min(crossEnd(c), crossEnd(from)) - Math.max(crossStart(c), crossStart(from)) > 0;
        const cross = Math.abs(crossCenter(c) - crossCenter(from));
        if (!inLine && cross > Math.abs(center(c) - center(from)))
            return;
        const score = inLine ? gap * 10 + cross : 1e6 + gap + cross * 2;
        if (score < bestScore) {
            bestScore = score;
            best = i;
        }
    });
    return best;
}
