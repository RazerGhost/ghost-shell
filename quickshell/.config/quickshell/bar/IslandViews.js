// Which view each of the island's pills shows below its top row (bar/IslandWindow.qml). Plain
// JavaScript, so it can be tested on its own (tests/tst_islandviews.qml).
.pragma library

// The pill a menu opens from: background apps from the arrow on the right; everything else from
// the middle, quick settings and power too (user's choice: opened by the status icons, but in the
// middle like before). "" for none.
const menus = {
    tray: "right",
    settings: "center", power: "center",
    today: "center", media: "center", clipboard: "center", emoji: "center"
};

function side(panel) {
    return menus[panel] ?? "";
}

// The view a pill shows: its open menu, else its hover view ("media" over the middle,
// "workspaces" over the left one, as "peek-<name>"), else "". `panel` is the open menu on this
// screen ("" for none), `peek` the hover view of this pill ("" for none).
function shown(pill, panel, peek) {
    if (side(panel) === pill)
        return panel;
    return panel === "" && peek !== "" ? "peek-" + peek : "";
}
