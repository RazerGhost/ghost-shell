// When to warn about disk space, for services/DiskAlerts.qml. Plain JavaScript, so it can be
// tested on its own (tests/tst_diskalerts.qml).
.pragma library

const lowAt = 0.10;      // free share of the disk
const criticalAt = 0.05;
const clearAt = 0.15;    // free again above this: the next shortage warns again

// `df -B1 --output=avail,size /` as { avail, size } in bytes, or null.
function parse(text) {
    const match = text.match(/^\s*(\d+)\s+(\d+)\s*$/m);
    return match ? { avail: Number(match[1]), size: Number(match[2]) } : null;
}

// What to do now: { warning: "critical" | "low" | "", given } where `given` is the most serious
// warning given so far ("" again once the disk has room), so each is given once per shortage.
function check(avail, size, given) {
    const free = avail / size;
    if (free > clearAt)
        return { warning: "", given: "" };
    if (free <= criticalAt && given !== "critical")
        return { warning: "critical", given: "critical" };
    if (free <= lowAt && given === "")
        return { warning: "low", given: "low" };
    return { warning: "", given: given };
}

// "42 GB" (decimal, like df -H and file managers).
function size(bytes) {
    return bytes >= 1e9 ? Math.round(bytes / 1e9) + " GB" : Math.round(bytes / 1e6) + " MB";
}
