// Which view each of the island's pills shows below its top row (bar/IslandWindow.qml). Plain
// JavaScript, so it can be tested on its own (tests/tst_islandviews.qml).
.pragma library

// The pill a menu opens from: quick settings, background apps and power from the status icons
// on the right; today, media, clipboard and emoji from the middle. "" for none.
const menus = {
    settings: "right", tray: "right", power: "right",
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
