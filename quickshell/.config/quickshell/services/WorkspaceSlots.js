// Which workspace dots the island shows, and where scrolling goes. Plain JavaScript, so it
// can be tested on its own (tests/tst_workspaces.qml).
.pragma library

// A workspace's id (a HyprlandWorkspace, or null). Quickshell reads every id as -1 from
// Hyprland 0.57.1's workspace list at start and learns the real ones from the first workspace
// event, so until then a numbered workspace's id comes from its name. Special workspaces (the
// scratchpad, minimized windows) keep theirs (-1: filtered out wherever ids > 0 are wanted).
function idOf(workspace) {
    if (!workspace)
        return null;
    if (workspace.id > 0)
        return workspace.id;
    const n = Number(workspace.name);
    return Number.isInteger(n) && n > 0 ? n : workspace.id;
}

// Ids 1..n: always at least `minimum` dots, more when a higher workspace exists, so a
// workspace you opened with Super+8 still gets a dot.
function slots(minimum, existingIds) {
    const n = Math.max(minimum, ...existingIds.filter(id => id > 0));
    return Array.from({ length: n }, (_, i) => i + 1);
}

// The workspace one step (delta = +1 or -1) away from `active`, wrapping around at the
// ends of the dots.
function step(active, delta, count) {
    return ((active - 1 + delta) % count + count) % count + 1;
}

// The workspace one step away from `active` among `slots` (the dots shown), wrapping around:
// with only the used ones shown, 2 -> 5 -> 8 rather than 2 -> 3.
function stepIn(slots, active, delta) {
    if (slots.length === 0)
        return active;
    const i = slots.indexOf(active);
    return slots[step(i < 0 ? 1 : i + 1, delta, slots.length) - 1];
}

// The workspaces in use, plus the one you're on, in order (the overview's strip). Hyprland removes an empty workspace once you leave it, so the ones that exist
// are the used ones; the active one counts even before it has a window.
function used(existingIds, active) {
    const ids = new Set(existingIds.filter(id => id > 0));
    ids.add(active);
    return Array.from(ids).sort((a, b) => a - b);
}
